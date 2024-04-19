classdef GPiPD < HeatmapModelSupport & handle
    %GPIDYSTONA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Tag = 'GPiPD'
        HeatmapModel
        b = [0.0802028065606909;0.0182106121333039;-0.216254361730454;0.0184558504465914;-0.315609689770560;-0.143292081194049;-0.407310593789638;-0.0491883957753293;-0.280129778736929;0.116743548799538;-0.0383197260219668;0;-0.182425158380182;-0.0282373797818319;0.00343527726644311;-0.209795938620256]
        edges = -1:0.13333333333:1;
    end
    
    methods
        function obj = GPiPD()
        addpath(fileparts(mfilename('fullpath')))
        end
        
        function obj = load(obj)
        
   
        hm = load('GPiPD_UPDRS%.heatmap','-mat');
        obj.HeatmapModel = hm.heatmap;
            
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
            global debug

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
            
            
            %check if it is on the right side then mirror
            if VTA_voxelData.getcog.x >1
                VTA_voxelData = VTA_voxelData.mirror();
            end
            
            %warp to heatmap space
            VTA_voxelData.warpto(obj.HeatmapModel.Signedpmap);
            
            if debug
                VTA_voxelData.getmesh(0.5).see(1)
            end
            
            %sample map to see if it's overlapping enough with the model!
            allvoxels = obj.HeatmapModel.Pmap.Voxels(VTA_voxelData.Voxels>0.5);
            outofmodel = sum(allvoxels==0);
            if outofmodel/numel(allvoxels)>0.3
                warning(['VTA (',VTA.Tag,') is partly outside the model! (',num2str(outofmodel/numel(allvoxels)*100),'%)']);
                
            end
            confidence = 1-outofmodel/numel(allvoxels);
            
            %sample those voxels where VTA and model both are.
            sample = obj.HeatmapModel.Signedpmap.Voxels(and(...
                VTA_voxelData.Voxels>0.5,...
                obj.HeatmapModel.Nmap.Voxels>0));
        end
        
        function y = predictForSample(obj,sample)
             f = figure('visible','off');
            h = histogram(sample,obj.edges);
            X = [1,zscore(h.Values)];
            y = X*obj.b;
            delete(f)
        end
        

    end
    
    methods (Static)
        
        
        function PostSettings = definePostProcessingSettings()
            
            msg =  'Which pipeline would you like to run?';
            opt = {'DEFAULT'};
            
            choiceIndex = listdlg('ListString',opt,'PromptString',msg);
            choice = opt{choiceIndex};
            
            switch choice
%              
%                 case 'Custom'  %temporarily switched off
%                      
%                     f = errordlg('Not available - wait for new version. (You might wait long)','Availibility problem');
%                     
%                 userinput = inputdlg({'Minimal confidence of the heatmap [0-1]',...
%                     'Amplitude optimization based on  n = ',...
%                     'Maximal accepted amplitude deviation (sigma)'},...
%                     'Post processing',...
%                     1,...
%                     {'0.5','5','1'});
%                 PostSettings.minConfidence = str2num(userinput{1});
%                 PostSettings.n = str2num(userinput{2});
%                 PostSettings.sigma = str2num(userinput{3});
%                 
%                 case 'DIPS (one SE Alt)'
%             
%             PostSettings.Mode = 'DIPS';
                case 'DEFAULT'
                    PostSettings.Mode = 'DEFAULT';
            
            end
        end
        
        function performReviewPostProcessing(tag,predictionList,PostSettings,pairs)
            
            switch PostSettings.Mode
                case 'DIPS'
                    
                    PostSettings.Therapy=GPiDystonia.getAltGPi(PostSettings.Therapy,PostSettings.sortedList);
                    HeatmapModelSupport.printList(PostSettings.Therapy,pairs)
                case 'DEFAULT' 
                    %nothing
            end
                    
                    
                    
                    
        end
            
%             blackOrRed = GPiDystonia.filterPredictions(predictionList,filterSettings);
%             HeatmapModelSupport.printPredictionList(tag,predictionList,pairs,blackOrRed);
%             
            
        
        
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
        
        
    
    
     function therapy = getAltGPi(therapy,sortedList)
         
         %side effects reducing alternative
         
         
         
            if numel(sortedList)<2
                
               therapy.AlternativeSettings = 'Sorry, but there are no alternative settings available for you. Practise your clinical programming.';
            else
            
            
            
            % use sorted list to pick settings with lower amplitudes and
            % more proximal contacts
            
            
            %  create list of predictions with lower amplitudes
            
            lenghtList=numel(sortedList);
            
            lowerAmpR=zeros(1,lenghtList);
            lowerAmpL=lowerAmpR;
            under3R=lowerAmpR;
            under3L=lowerAmpR;
            under4proxR=lowerAmpR;
            under4proxL=lowerAmpR;
            
            for ii=1:lenghtList
            
            lowerAmpR(1,ii)=sortedList(1,ii).Input.VTAs(1).Settings.amplitude<therapy.RecommendedSettings.Input.VTAs(1).Settings.amplitude;
            lowerAmpL(1,ii)=sortedList(1,ii).Input.VTAs(2).Settings.amplitude<therapy.RecommendedSettings.Input.VTAs(2).Settings.amplitude;
            
            
            
            %  is there something under 3,5 mA bds? 
            under3R(1,ii) = sortedList(1,ii).Input.VTAs(1).Settings.amplitude<3.5;
            under3L(1,ii) = sortedList(1,ii).Input.VTAs(2).Settings.amplitude<3.5;
            
            
            % is there something under 4,5 mA with more proximal contacts 
            
            under4proxR(1,ii) = (sortedList(1,ii).Input.VTAs(1).Settings.amplitude<4.5)&(therapy.RecommendedSettings.Input.VTAs(1).Settings.activecontact...
                <sortedList(1,ii).Input.VTAs(1).Settings.activecontact);
            
            under4proxL(1,ii) = (sortedList(1,ii).Input.VTAs(2).Settings.amplitude<4.5)&(therapy.RecommendedSettings.Input.VTAs(2).Settings.activecontact...
                <sortedList(1,ii).Input.VTAs(2).Settings.activecontact);
            
            end
            
            lowerAmp=lowerAmpR&lowerAmpL;
            under3 = under3R&under3L;
            
            under4prox = under4proxR&under4proxL;
            
            if sum(under3&lowerAmp) % if there are settings with lower amplitudes under 3,5, take it
                
                altList=sortedList(under3&lowerAmp);
                
                
            elseif sum(under4prox) %if there is something under 4,5 bds more proximal
                
                altList=sortedList(under4prox);
                
            elseif sum(lowerAmp) % if not just take lower amp bds
                
                altList=sortedList(lowerAmp);
                
            else
                
                altList(1,1)=0;
                
            end
            
            if altList(1,1) == 0
                
                therapy.AlternativeSettings = 'We are very sorry, but it seems that to avoid the side effects, you will need to adjust your stimulation clinicaly.';
                
            else
                
                therapy.AlternativeSettings = altList(1,1);
                
            end
            
            end
            
         
            
     end
        
    end
                
end


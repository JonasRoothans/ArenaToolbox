classdef Therapy < handle
    %THERAPY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        VTAs = VTA.empty;
        Predictions = Prediction.empty;
        ReviewOutcome = Prediction.empty;
        ReviewData
        Tag
    end
    
    methods
        function obj = Therapy(Tag)
            %THERAPY Construct an instance of this class
            %   Detailed explanation goes here
            if nargin==1
                obj.Tag = Tag;
            end
        end
        
        function obj = addVTA(obj,VTA)
            for i = 1:numel(VTA)
                if isa(VTA(i),'VTA')
                    obj.VTAs(end+1) = VTA(i);
                end
            end
            
        end
        
        function obj = connectTo(obj,scene)
            scene.Therapystorage(end+1) = obj;
        end
        
        
        function p =  executePrediction(obj,heatmap)
            global predictionmanager
            if nargin==1
                p = predictionmanager.newPrediction(obj);
            else
                p = predictionmanager.newPrediction(obj,heatmap);
            end
            obj.Predictions(end+1) = p;
            
            
        end
        
        
        function obj = executeReview(obj)
            %check available electrodes:
            Electrode_list = {obj.VTAs(:).Electrode};
            Electrode_present = not(cellfun(@isempty,{obj.VTAs(:).Electrode}));
            
            %throw error if lead objects are missing.
            if sum(Electrode_present)<numel(Electrode_list)
                msg = sprintf('- %s\n', obj.VTAs(not(Electrode_present)).Tag);
                error([sprintf('The following VTAs did not contain an electrode:\n'),msg])
            end
            
            %connect VTA pool
            global arena
            if not(isfield(arena.Settings,'VTApool'))
                waitfor(msgbox('Your config file is outdated. Please delete config.mat and fully close MATLAB. At next use Arena will run the installation menu'))
                return
            end
            
            %ask for heatmap/model
            global predictionmanager
            heatmap = predictionmanager.selectHeatmap();
            
            %Ask for mode
            options = {'60 us - 1,2,3,4,5 mA - MDT3389',...
                '60 us - 0.1mA steps - MDT3389',...
                '60 us - 0.5 mA steps - MDT3389',...
                '60 us - just 2.5 mA - MDT3389',...
                '120 us - 0.5 mA steps - MDT3389',...
                '60 us - just 2 and 4 mA- MDT3389'};
            
            answer = listdlg('PromptString','Select monopolar review preset (can be updated in Therapy.m):','ListString',options,'ListSize',[400,100]);
            switch options{answer}
                case '60 us - 1,2,3,4,5 mA - MDT3389'
                    leadtype = {'Medtronic3389'};
                    voltagecontrolled = {'False'};
                    pulsewidths = {60};
                    amplitudes = num2cell(1:5);
                    contacts = num2cell(1:4);
                case '60 us - 0.1mA steps - MDT3389'
                    leadtype = {'Medtronic3389'};
                    voltagecontrolled = {'False'};
                    pulsewidths = {60};
                    amplitudes = num2cell(1:0.1:6.9);
                    contacts = num2cell(1:4);
                case '60 us - 0.5 mA steps - MDT3389'
                    leadtype = {'Medtronic3389'};
                    voltagecontrolled = {'False'};
                    pulsewidths = {60};
                    amplitudes = num2cell(1:0.5:6.5);
                    contacts = num2cell(1:4);
                case '60 us - just 2.5 mA - MDT3389'
                    leadtype = {'Medtronic3389'};
                    voltagecontrolled = {'False'};
                    pulsewidths = {60};
                    amplitudes = num2cell(2.5);
                    contacts = num2cell(1:4);
                case '60 us - just 2 and 4 mA- MDT3389'
                    leadtype = {'Medtronic3389'};
                    voltagecontrolled = {'False'};
                    pulsewidths = {60};
                    amplitudes = num2cell(2:2:4);
                    contacts = num2cell(1:4);
                case '120 us - 0.5 mA steps - MDT3389'
                    leadtype = {'Medtronic3389'};
                    voltagecontrolled = {'False'};
                    pulsewidths = {120};
                    amplitudes = num2cell(1.5:0.5:5.5);
                    contacts = num2cell(1:4);
                otherwise
                    keyboard
            end
            
            %Ask for postprocessing filter settings
            PostSettings = heatmap.definePostProcessingSettings();
            
            
            %define VTAnames
            [VTAnames,settings] = generateVTAnames(leadtype,amplitudes,pulsewidths,voltagecontrolled);
            
            %pair up VTAs
            if sum(Electrode_present)==2
                [a,b] = meshgrid(1:length(VTAnames),1:length(VTAnames));
                pairs = [a(:),b(:)];
            else
                pairs = (1:length(VTAnames))';
            end
            
            
            %Loop over pairs
            output = [];
            predictionList = Prediction.empty;
            comments = {};
            
            for iPair = 1:length(pairs)
                thisPair = pairs(iPair,:);
                if length(thisPair)==2
                    
                    electrode1 = obj.VTAs(1).Electrode;
                    electrode2 = obj.VTAs(2).Electrode;
                    
                    vtaname1 = VTAnames{thisPair(1)};
                    vtaname2 = VTAnames{thisPair(2)};
                    
                    vta1 = electrode1.makeVTA(vtaname1);
                    vta1.Space = obj.VTAs(1).Space;
                    vta1.Settings = settings(thisPair(1));
                    
                    vta2 = electrode2.makeVTA(vtaname2);
                    vta2.Space = obj.VTAs(2).Space;
                    vta2.Settings = settings(thisPair(2));
                    
                    newTherapy = Therapy;
                    newTherapy.addVTA(vta1);
                    newTherapy.addVTA(vta2);
                    
                    p = newTherapy.executePrediction(heatmap);
                    
                    predictionList(iPair) = p;
                    
                    
                else %unilateral
                    electrode1 = obj.VTAs(1).Electrode;
                    
                    vtaname1 = VTAnames{thisPair(1)};
                    
                    vta1 = electrode1.makeVTA(vtaname1);
                    vta1.Space = obj.VTAs(1).Space;
                    vta1.Settings = settings(thisPair(1));
                    
                    newTherapy = Therapy;
                    newTherapy.addVTA(vta1);
                    
                    p = newTherapy.executePrediction(heatmap);
                    predictionList(iPair) = p;
                    
                end
            end
            
            
            %make export directory
            p = mfilename('fullpath');
            arenaDir= fileparts(fileparts(p));
            currentDir = fullfile(arenaDir,'UserData','Monpolar Review',obj.Tag);
            [~,msg] = mkdir(currentDir);
            counter = 1;
            while strcmp(msg,'Directory already exists.')
                currentDir = fullfile(arenaDir,'UserData','Monpolar Review',[obj.Tag,' (',num2str(counter),')']);
                [~,msg] = mkdir(currentDir);
                counter = counter+1;
            end
            
            
            %order and filter the suggestions
            %-- sort on improvement
            [sorted,order] = sort(vertcat(predictionList.Output),'descend');
            ReviewData.predictionList = predictionList;
            ReviewData.order = order;
            ReviewData.filterSettings = PostSettings;
%             
%             %save(fullfile(currentDir,'therapy'),'ReviewData');
%             
%             %             %calculate power consumption
%             powerConsumption = [];
%             for iPair = 1:length(order)
%                 sum_of_amplitudes = 0;
%                 for iVTA = 1:numel(ReviewData.predictionList(iPair).Input.VTAs)
%                     sum_of_amplitudes  =  sum_of_amplitudes+ ReviewData.predictionList(iPair).Input.VTAs(iVTA).Settings.amplitude;
%                 end
%                 powerConsumption(iPair) = sum_of_amplitudes/iVTA;
%             end
%             
%             
%             power_sorted = powerConsumption(order);
%             
%             %             %-- confidence check
%             leastconfidence = min(vertcat(ReviewData.predictionList(:).Confidence)');
%             if length(leastconfidence)==1
%                 passedConfidenceTest = vertcat(ReviewData.predictionList(:).Confidence)' > ReviewData.filterSettings.minConfidence;
%             else
%                 passedConfidenceTest = leastconfidence > ReviewData.filterSettings.minConfidence;
%             end
%             %
%             %             %-- outlier amplitudes
%             power_filtered_and_sorted = power_sorted(passedConfidenceTest);
%             
%             if length(power_filtered_and_sorted)<ReviewData.filterSettings.n
%                 ReviewData.filterSettings.n = length(power_filtered_and_sorted);
%             end
%             mu_power = mean(power_filtered_and_sorted(1:ReviewData.filterSettings.n));
%             sigma_power = std(power_filtered_and_sorted(1:ReviewData.filterSettings.n));
%             amp_cutoff = mu_power+sigma_power*ReviewData.filterSettings.sigma;
%             passedAmpTest = power_sorted<amp_cutoff;
%             
%             if sigma_power==0 %if all amps are equal, all should pass.
%                 passedAmpTest = true(1,length(passedAmpTest));
%             end
%             
            %open file
            fileID = fopen(fullfile(currentDir,'RankedScores.txt'),'w');
            clc
            showVTA = 1;
            
            if length(thisPair)==2
                printtext(fileID,'\t\t\t%s\t%s\n',obj.VTAs(1).ActorElectrode.Tag,obj.VTAs(2).ActorElectrode.Tag);
                printtext(fileID,'-------------------------------------------\n')
                for iShortlist = 1:length(order)
                    item = order(iShortlist);
                    Improv = predictionList(item).Output;
                    c_e1 = predictionList(item).Input.VTAs(1).Settings.activecontact;
                    c_e2 = predictionList(item).Input.VTAs(2).Settings.activecontact;
                    a_e1 = predictionList(item).Input.VTAs(1).Settings.amplitude;
                    a_e2 = predictionList(item).Input.VTAs(2).Settings.amplitude;
                    conf_e1 = predictionList(item).Confidence(1);
                    conf_e2 = predictionList(item).Confidence(2);
                   
                    printtext(fileID,'%i.\t %2.1f \t C%i - %2.1f mA\t C%i - %2.1f mA \t (%2.2f / %2.2f) \n',iShortlist,Improv, c_e1,a_e1,c_e2,a_e2,conf_e1,conf_e2);
                    
                    %visualise the best
                    if not(showVTA)
                        scene = obj.VTAs(1).ActorElectrode.Scene;
                        vta1 = predictionList(item).Input.VTAs(1).Volume.getmesh(0.5).see(scene);
                        vta1.changeName('Best');
                        vta2 = predictionList(item).Input.VTAs(2).Volume.getmesh(0.5).see(scene);
                        vta2.changeName('Best');
                        showVTA = 0;
                    end
                        
                       
                end
            else
                for iShortlist = 1:length(order)
                    %                 thisPair = ReviewData.pairs(order(iShortlist),:);
                    item = order(iShortlist);
                    Improv = predictionList(item).Output;
                    c_e1 = predictionList(item).Input.VTAs(1).Settings.activecontact;
                    
                    a_e1 = predictionList(item).Input.VTAs(1).Settings.amplitude;
                    
                    conf_e1 = predictionList(item).Confidence(1);
                    
                    
                    
                    
                    printtext(fileID,'%i.\t %2.1f \t C%i - %2.1f mA\t (%2.2f) \n',iShortlist,Improv, c_e1,a_e1,conf_e1);
                    
                end
            end
            
            fclose(fileID);
            
            %Store best therapy
        
     
            obj.ReviewOutcome(end+1) = predictionList(order(1));
            obj.ReviewOutcome(end+1) = predictionList(order(2));
            obj.ReviewOutcome(end+1) = predictionList(order(3));
            
            
            
            function printtext(fid,varargin)
                fprintf(fid,varargin{:});
                fprintf(varargin{:});
            end
            
            function [VTAnames,Settings] = generateVTAnames(leadtype,amplitudes,pulsewidths,voltagecontrolled)
                VTAnames = {};
                Settings = [];
                i = 0;
                for iLeadType = 1:numel(leadtype)
                    thisLeadType = leadtype{iLeadType};
                    for iPulseWidth = 1:numel(pulsewidths)
                        thisPulseWidth = pulsewidths{iPulseWidth};
                        for iVoltageControlled  = 1:numel(voltagecontrolled)
                            thisVoltageControlled = voltagecontrolled{iVoltageControlled};
                            for iContact = 1:4
                                for iAmplitude = 1:numel(amplitudes)
                                    thisAmplitude = amplitudes{iAmplitude};
                                    i = i+1;
                                    thisContact = iContact;
                                    activecontact = [0 0 0 0];
                                    activecontact(thisContact) = 1;
                                    groundedcontact = [0 0 0 0];
                                    
                                    
                                    VTAnames{i} = VTA.constructVTAname(...
                                        thisLeadType,...
                                        thisAmplitude,...
                                        thisPulseWidth,...
                                        activecontact,...
                                        groundedcontact,...
                                        thisVoltageControlled);
                                    
                                    
                                    Settings(i).amplitude = thisAmplitude;
                                    Settings(i).leadtype  = thisLeadType;
                                    Settings(i).pulsewidth = thisPulseWidth;
                                    Settings(i).activecontact = iContact-1;
                                    
                                    
                                end
                            end
                        end
                    end
                end
            end
            
            
%             function name = constructVTAname(leadtype,amplitude,pulsewidth,activevector,groundedcontact,voltagecontrolled)
%                 
%                 name = [leadtype,...
%                     num2str(amplitude),...
%                     num2str(voltagecontrolled),...
%                     num2str(pulsewidth),...
%                     'c',strrep(num2str(activevector),'  ',' '),...
%                     'a',strrep(num2str(groundedcontact),'  ',' '),...
%                     '.mat'];
%             end
%             
            
        end
        
        function exploreReview(obj)
            
            
            powerConsumption = [];
            %calculate powerconsumption
            for iPair = 1:length(obj.ReviewData.pairs)
                thisPair = obj.ReviewData.pairs(iPair,:);
                powerConsumption(thisPair(1),thisPair(2)) = obj.ReviewData.settings(thisPair(1)).amplitude + obj.ReviewData.settings(thisPair(2)).amplitude+rand()-0.5;;
                
            end
            
            leastconfidence = cellfun(@min,obj.ReviewData.confidence);
            meanconfidence = cellfun(@mean,obj.ReviewData.confidence);
            passedConfidenceTest = leastconfidence > 0.5;
            passedImprovementTest = obj.ReviewData.output>=prctile(obj.ReviewData.output(:),80);
            passedBoth = and(passedConfidenceTest,passedImprovementTest);
            
            powerConsumption_ = powerConsumption(passedBoth);
            output_ = obj.ReviewData.output(passedBoth);
            
            distances = squareform(pdist([powerConsumption_,output_]));
            distances(distances==0)=1000;
            distmatrix = min(distances)';
            
            [s_output_,order] = sort(output_,'descend');
            s_powerConsumption_ = powerConsumption_(order);
            
            [x,mu,sigma] = zscore(s_powerConsumption_(1:5));
            colr = ((s_powerConsumption_-mu)/sigma)>1;
            
            figure;
            scatter(s_powerConsumption_,s_output_,100,double(colr),'filled')
            
            colormap('winter')
            xlabel('PowerConsumption')
            ylabel('Improvement')
            
        end
        
    end
end


classdef Therapy < handle
    %THERAPY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        VTAs = VTA.empty;
        Predictions = Prediction.empty;
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
            userinput = inputdlg({'Minimal confidence of the heatmap [0-1]',...
                'Amplitude optimization based on  n = ',...
                'Maximal accepted amplitude deviation (sigma)'},...
                'Post processing',...
                1,...
                {'0.5','5','1'});
            filterSettings.minConfidence = str2num(userinput{1});
            filterSettings.n = str2num(userinput{2});
            filterSettings.sigma = str2num(userinput{3});
            
            
            
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
            comments = {};
            h_wb = waitbar(0,'doing magic...');
            
            for iPair = 1:length(pairs)
                waitbar(iPair/length(pairs),h_wb);
                thisPair = pairs(iPair,:);
                if length(thisPair)==2
                    electrode1 = obj.VTAs(1).Electrode;
                    electrode2 = obj.VTAs(2).Electrode;
                    
                    vtaname1 = VTAnames{thisPair(1)};
                    vtaname2 = VTAnames{thisPair(2)};
                    
                    vta1 = electrode1.makeVTA(vtaname1);
                    vta1.Space = obj.VTAs(1).Space;
                    
                    vta2 = electrode2.makeVTA(vtaname2);
                    vta2.Space = obj.VTAs(2).Space;
                    
                    newTherapy = Therapy;
                    newTherapy.addVTA(vta1);
                    newTherapy.addVTA(vta2);
                    
                    p = newTherapy.executePrediction(heatmap);
                    output(thisPair(1),thisPair(2)) = p.Output;
                    confidence{thisPair(1),thisPair(2)} = p.Confidence;
                    comments{thisPair(1),thisPair(2)} = p.Comments;
                    
                    Xoutput(iPair) = p.Output;
                    Xconfidence{iPair} = p.Confidence;
                    Xcomments{iPair} = p.Comments;
                    
                    
                else
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
            
            %save data
            ReviewData.output = output;
            ReviewData.comments = comments;
            ReviewData.VTAnames = VTAnames;
            ReviewData.settings = settings;
            ReviewData.confidence = confidence;
            ReviewData.pairs = pairs;
            ReviewData.filterSettings = filterSettings;
            obj.ReviewData = ReviewData;
            
            save(fullfile(currentDir,'therapy'),'ReviewData');
            
            %calculate power consumption
            for iPair = 1:length(ReviewData.pairs)
                thisPair = ReviewData.pairs(iPair,:);
                powerConsumption(thisPair(1),thisPair(2)) = ReviewData.settings(thisPair(1)).amplitude + ReviewData.settings(thisPair(2)).amplitude;
                
            end
            
            %order and filter the suggestions
            %-- sort on improvement
            [sorted,order] = sort(ReviewData.output(:),'descend');
            [Xsorted,Xorder] = sort(Xoutput(:),'descend');
            power_sorted = powerConsumption(order);
            confidence_sorted = ReviewData.confidence(order);
            
            %-- confidence check
            leastconfidence = cellfun(@min,confidence_sorted);
            passedConfidenceTest = leastconfidence > ReviewData.filterSettings.minConfidence;
            
            %-- outlier amplitudes
            power_filtered_and_sorted = power_sorted(passedConfidenceTest);
            mu_power = mean(power_filtered_and_sorted(1:ReviewData.filterSettings.n));
            sigma_power = std(power_filtered_and_sorted(1:ReviewData.filterSettings.n));
            amp_cutoff = mu_power+sigma_power*ReviewData.filterSettings.sigma;
            passedAmpTest = power_sorted<amp_cutoff;
            
            if sigma_power==0 %if all amps are equal, all should pass.
                passedAmpTest = true(1,length(passedAmpTest));
            end
            
            
            
            
            
            fileID = fopen(fullfile(currentDir,'RankedScores.txt'),'w');
  
            clc
            printtext(fileID,'\t\t\t%s\t%s\n',obj.VTAs(1).ActorElectrode.Tag,obj.VTAs(2).ActorElectrode.Tag);
            printtext(fileID,'-------------------------------------------\n')
            for iShortlist = 1:length(order)
                thisPair = ReviewData.pairs(order(iShortlist),:);
                Improv = sorted(iShortlist);
                c_e1 = ReviewData.settings(thisPair(1)).activecontact;
                c_e2 = ReviewData.settings(thisPair(2)).activecontact;
                a_e1 = ReviewData.settings(thisPair(1)).amplitude;
                a_e2 = ReviewData.settings(thisPair(2)).amplitude;
                %conf = ReviewData.confidence{thisPair(1),thisPair(2)}; %<< confidence seems to be mixed up
                
                 conf = ReviewData.confidence{thisPair(2),thisPair(1)};
                
                conf_e1 = conf(1);
                conf_e2 = conf(2);
                
                confidenceTest = passedConfidenceTest(iShortlist);
                ampTest = passedAmpTest(iShortlist);
                
                if not(and(confidenceTest, ampTest))
                    printtext(fileID, '__.\t %2.1f \t C%i - %2.1f mA\t C%i - %2.1f mA \t (%2.2f / %2.2f) \n',Improv, c_e1,a_e1,c_e2,a_e2,conf_e1,conf_e2);
                    
                else
                    printtext(fileID,'%i.\t %2.1f \t C%i - %2.1f mA\t C%i - %2.1f mA \t (%2.2f / %2.2f) \n',iShortlist,Improv, c_e1,a_e1,c_e2,a_e2,conf_e1,conf_e2);
                    
                end
                
                if iShortlist < 11
                    scatter(a_e1+a_e2,Improv)
                end
                
            end
            
            fclose(fileID);
            
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
                                    
                                    
                                    
                                    
                                    VTAnames{i} = constructVTAname(...
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
            
            
            function name = constructVTAname(leadtype,amplitude,pulsewidth,activevector,groundedcontact,voltagecontrolled)
                
                name = [leadtype,...
                    num2str(amplitude),...
                    num2str(voltagecontrolled),...
                    num2str(pulsewidth),...
                    'c',strrep(num2str(activevector),'  ',' '),...
                    'a',strrep(num2str(groundedcontact),'  ',' '),...
                    '.mat'];
            end
            
            
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


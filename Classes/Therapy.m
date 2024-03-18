classdef Therapy < handle
    %THERAPY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        VTAs = VTA.empty;
        Predictions = Prediction.empty;
        ReviewOutcome = Prediction.empty;
        ReviewData
        RecommendedSettings
        AlternativeSettings
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
        
        
        
        function [obj,predictionlist] = executeReview(obj,OptionalInput)
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
            
            if nargin>1 %use provided input to skip user dialogs
                UserChoices = OptionalInput;
            else %ask for user input
                UserChoices = Therapy.UserInputModule();
            end
            heatmap = UserChoices.heatmap;
            VTAset = UserChoices.VTAset;
            PostSettings = UserChoices.PostSettings;
            
            %generate VTA options based on user or machine selection.
            switch VTAset
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
                case '60 us - 3.2 mA steps - MDT3389 (cogn. decline monopolar review)'
                    leadtype = {'Medtronic3389'};
                    voltagecontrolled = {'False'};
                    pulsewidths = {60};
                    amplitudes = num2cell(3.2);
                    contacts = num2cell(1:4);
                case '60 us - 2 mA - MDT3389 QUICKSCAN'
                    leadtype = {'Medtronic3389'};
                    voltagecontrolled = {'False'};
                    pulsewidths = {60};
                    amplitudes = num2cell(2);
                    contacts = num2cell(1:4);
                case '60 us - 1,2,3,4,5 mA ANY electrode'
                    leadtype = {obj.VTAs(1).Electrode.Type};
                    if numel(obj.VTAs)>1
                        if not(strcmp(obj.VTAs(1).Electrode.Type,obj.VTAs(2).Electrode.Type))
                            warning(['Patient ',obj.Tag,' has two different electrodes. For this analysis ',leadtype,' will be used!'])
                        end
                    end
                    voltagecontrolled = {'False'};
                    pulsewidths = {60};
                    amplitudes = num2cell(1:5);
                    contacts = num2cell(1:4);
                otherwise
                    keyboard
            end
            
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
            predictionList = Prediction.empty;
            
            
            fwait = waitbar(0,['Running monopolar review: ',heatmap.Tag]);
            
            
            for iPair = 1:length(pairs)
                waitbar(iPair/(length(pairs)+1),fwait);
                thisPair = pairs(iPair,:);
                newTherapy = Therapy;
                
                %vta 1
                electrode1 = obj.VTAs(1).Electrode;
                vtaname1 = VTAnames{thisPair(1)};
                vta1 = electrode1.makeVTA(vtaname1);
                vta1.Space = obj.VTAs(1).Space;
                vta1.Settings = settings(thisPair(1));
                vta1.ActorElectrode = obj.VTAs(1).ActorElectrode;
                newTherapy.addVTA(vta1);
                
                %vta 2
                if length(thisPair)==2
                    electrode2 = obj.VTAs(2).Electrode;
                    vtaname2 = VTAnames{thisPair(2)};
                    vta2 = electrode2.makeVTA(vtaname2);
                    vta2.Space = obj.VTAs(2).Space;
                    vta2.Settings = settings(thisPair(2));
                    vta2.ActorElectrode = obj.VTAs(2).ActorElectrode;
                    newTherapy.addVTA(vta2);
                end
                
                p = newTherapy.executePrediction(heatmap);
                predictionList(iPair) = p;
                
                
            end %loop
            
            %close waitbar
            close(fwait)
            %add predictionlist to therapyObject
            obj.ReviewData.predictionList = predictionList;
            
            
            %Now there are 2 options for postprocessing:
            % 1) do a custom postprocessing for the heatmapmodel
            % 2) simply perform basics of printing the data, with creating
            %  recommended settings based on improvement and confidence (this hapens everytime)
            
            [obj,sortedList] = obj.getReco;
            
            %--- option 1: do a custom postprocessing for the heatmapmodel
            if isa(PostSettings,'struct')
                
                %add self to postsettings. Might come in handy
                PostSettings.Therapy = obj;
                PostSettings.UserInput.heatmap = heatmap;
                PostSettings.UserInput.VTAset = VTAset;
                
                PostSettings.sortedList=sortedList;
                
                %run the postprocessing in the model.
                
                
                heatmap.performReviewPostProcessing(obj.Tag,predictionList,PostSettings,pairs);
                
                
                %--- option 2: simply perform basics of printing the data.
            else
                
                
                
                if false
                    
                    [~,order] = sort([predictionList.Output],'descend');
                    for iPrint = 1:length(order)
                        disp([num2str(iPrint),...
                            '. ',num2str(predictionList(order(iPrint)).Output),...
                            ', contact: ',num2str(predictionList(order(iPrint)).Input.VTAs.Settings.activecontact),...
                            ', amplitude: ',num2str(predictionList(order(iPrint)).Input.VTAs.Settings.amplitude)])
                    end
                    
                else
                    
                    
                    
                    %% print everything using heatmap support
                    
                    
                    fileID = HeatmapModelSupport.printPredictionList(obj.Tag,obj.ReviewData.predictionList,pairs);
                    %HeatmapModelSupport.printtext(fileID,'\n')
                    %HeatmapModelSupport.printtext(fileID,'Therapy Recommendation:')
                    %HeatmapModelSupport.printtext(fileID,'\n')
                    %HeatmapModelSupport.printReco(fileID,therapy.RecommendedSettings,pairs)
                    fclose(fileID);
                    
                    
                    
                    %%
                    
                    %order and filter the suggestions
                    %-- sort on improvement
                    
                    [sorted,order] = sort(vertcat(predictionList.Output),'descend');
                    
                    obj.ReviewData.order = order;
                    obj.ReviewData.filterSettings = PostSettings;
                    
                end
                
                
                %Store best therapy
                obj.ReviewOutcome(end+1) = predictionList(order(1));
                obj.ReviewOutcome(end+1) = predictionList(order(2));
                obj.ReviewOutcome(end+1) = predictionList(order(3));
                
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
            
            
            
        end
        
        %% Postprocessing Pavel
        
        function [obj,sortedList] = getReco(obj) %this function sorts out low confidences, orders in respect to confidence and impro
            
            predictionList=obj.ReviewData.predictionList;
            
            
            if ~numel(predictionList)
                error('First construct a prediction list, then you can ask for a recommendation!')
            else
                
                highConf = min(vertcat(predictionList(:).Confidence)')>0.89;
                TopConfList = predictionList(highConf);
                
                lowConf = min(vertcat(predictionList(:).Confidence)')>0.59;
                LowConfList = predictionList(lowConf);
                
                if numel(TopConfList)>1
                    
                    [~,orderTop] = sort(vertcat(TopConfList.Output),'descend');
                    orderTop = orderTop';
                    TopConfList = TopConfList(orderTop);
                    
                    
                end
                
                ConfSum = sum(vertcat(LowConfList(:).Confidence),2);
                
                [~,orderLow] = sort(vertcat(LowConfList(:).Output).*ConfSum);
                orderLow = orderLow';
                LowConfList = LowConfList(orderLow);
                
                sortedPredictionList = horzcat(TopConfList,LowConfList);
                
                if nargout > 0
                    
                    sortedList = sortedPredictionList;
                end
                
                if numel(sortedPredictionList)>0
                    
                    obj.RecommendedSettings = sortedPredictionList(1,1);
                    
                else
                    
                    obj.RecommendedSettings = 'No recommendation possible';
                    
                end
                
            end
            
            
        end
        
        
        
        
        
        
        
        
        %%
        
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
    
    methods (Static)
        function UserChoices = UserInputModule(presets)
            if nargin==0
                presets.heatmap = [];
                presets.VTAset = [];
                presets.PostSettings = [];
            end
            %ask for heatmap/model
            global predictionmanager
            if isempty(presets.heatmap)
                heatmap = predictionmanager.selectHeatmap();
            else
                heatmap = presets.heatmap;
            end
            
            %Ask for mode
            options = {'60 us - 1,2,3,4,5 mA - MDT3389',...
                '60 us - 0.1mA steps - MDT3389',...
                '60 us - 0.5 mA steps - MDT3389',...
                '60 us - just 2.5 mA - MDT3389',...
                '120 us - 0.5 mA steps - MDT3389',...
                '60 us - just 2 and 4 mA- MDT3389',...
                '60 us - 3.2 mA steps - MDT3389 (cogn. decline monopolar review)',...
                '60 us - 2 mA - MDT3389 QUICKSCAN',...
                '60 us - 1,2,3,4,5 mA ANY electrode'};
            
            if isempty(presets.VTAset)
                answer = listdlg('PromptString','Select monopolar review preset (can be updated in Therapy.m):','ListString',options,'ListSize',[400,100]);
                VTAset = options{answer};
            else
                VTAset = presets.VTAset;
            end
            
            %Ask for postprocessing filter settings. (heatmap specific)
            if isempty(presets.PostSettings)
                PostSettings = heatmap.definePostProcessingSettings();
            else
                PostSettings = presets.PostSettings;
            end
            
            UserChoices.heatmap = heatmap;
            UserChoices.VTAset = VTAset;
            UserChoices.PostSettings = PostSettings;
        end
    end
    
    
end


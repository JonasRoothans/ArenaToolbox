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
            % 2) simply perform basics of printing the data.
            
            %--- option 1: do a custom postprocessing for the heatmapmodel
            if isa(PostSettings,'struct')
                
                %add self to postsettings. Might come in handy
                PostSettings.Therapy = obj;
                PostSettings.UserInput.heatmap = heatmap;
                PostSettings.UserInput.VTAset = VTAset;
                
                %run the postprocessing in the model.
                heatmap.performReviewPostProcessing(obj.Tag,predictionList,PostSettings,pairs)
                
                %--- option 2: simply perform basics of printing the data.
            else
                
                %sort list according to improvement as well as confidence and
                %asign recommended settings
                
                if false
                    
                    [~,order] = sort([predictionList.Output],'descend');
                    for iPrint = 1:length(order)
                        disp([num2str(iPrint),...
                            '. ',num2str(predictionList(order(iPrint)).Output),...
                            ', contact: ',num2str(predictionList(order(iPrint)).Input.VTAs.Settings.activecontact),...
                            ', amplitude: ',num2str(predictionList(order(iPrint)).Input.VTAs.Settings.amplitude)])
                    end
                    
                else
                    sortedList = sortImproConf(obj, predictionList);
                    if numel(sortedList)
                        obj.RecommendedSettings = sortedList(1,1);
                    else
                        obj.RecommendedSettings = {'No recommendation based on this model possible'};
                        
                    end
                    
                    
                    
                    %% print recommendations
                    
                    fileID = HeatmapModelSupport.makeFile(obj.Tag);
                    HeatmapModelSupport.printtext(fileID,'\n')
                    HeatmapModelSupport.printtext(fileID,'Recommended Settings\n')
                    HeatmapModelSupport.printtext(fileID,'\n')
                    if iscell(obj.RecommendedSettings)
                        HeatmapModelSupport.printtext(fileID,'No recommendation based on this model possible\n')
                        HeatmapModelSupport.printtext(fileID,'\n')
                    else
                        HeatmapModelSupport.printPredictionList(obj.Tag,obj.RecommendedSettings,pairs,nan)
                    end
                    
                    %             if ~iscell(obj.AlternativeSettings.universal)
                    %                 HeatmapModelSupport.printtext(fileID,'\n')
                    %                 HeatmapModelSupport.printtext(fileID,'Alternative settings reducing side effects from both hemispheres is\n')
                    %                 HeatmapModelSupport.printtext(fileID,'\n')
                    %                 HeatmapModelSupport.printPredictionList(obj.Tag,obj.AlternativeSettings.universal,pairs,nan)
                    %             else
                    %                 if ~iscell(obj.AlternativeSettings.leftHemisphereSE)
                    %                     HeatmapModelSupport.printtext(fileID,'\n')
                    %                      HeatmapModelSupport.printtext(fileID,'Alternative settings reducing side effects from left hemisphere is\n')
                    %                      HeatmapModelSupport.printtext(fileID,'\n')
                    %                 HeatmapModelSupport.printPredictionList(obj.Tag,obj.AlternativeSettings.leftHemisphereSE,pairs,nan)
                    %                 end
                    %
                    %                  if ~iscell(obj.AlternativeSettings.rightHemisphereSE)
                    %                      HeatmapModelSupport.printtext(fileID,'\n')
                    %                      HeatmapModelSupport.printtext(fileID,'Alternatice settings reducing side effects from right hemisphere hemispheres is\n')
                    %                      HeatmapModelSupport.printtext(fileID,'\n')
                    %                 HeatmapModelSupport.printPredictionList(obj.Tag,obj.AlternativeSettings.rightHemisphereSE,pairs,nan)
                    %                  end
                    %
                    %                 if ~iscell(obj.AlternativeSettings.ampReduction)
                    %                     HeatmapModelSupport.printtext(fileID,'\n')
                    %                     HeatmapModelSupport.printtext(fileID,'Alternative settings with reduced amplitudes is\n')
                    %                     HeatmapModelSupport.printtext(fileID,'\n')
                    %                     HeatmapModelSupport.printPredictionList(obj.Tag,obj.AlternativeSettings.ampReduction,pairs,nan)
                    %                     HeatmapModelSupport.printtext(fileID,'\n')
                    %                 end
                    %
                    %                 if iscell(obj.AlternativeSettings.ampReduction)&iscell(obj.AlternativeSettings.rightHemisphereSE)&...
                    %                         iscell(obj.AlternativeSettings.leftHemisphereSE)&iscell(obj.AlternativeSettings.universal)
                    %                     HeatmapModelSupport.printtext(fileID,'\n')
                    %                     HeatmapModelSupport.printtext(fileID,'No side effects reducing suggestion possible, consider manual ampitude reduction\n')
                    %                     HeatmapModelSupport.printtext(fileID,'\n')
                    %                 end
                    %             end
                    HeatmapModelSupport.printtext(fileID,'WHOLE REVIEW\n')
                    HeatmapModelSupport.printtext(fileID,'\n')
                    
                    %%
                
                    %order and filter the suggestions
                    %-- sort on improvement
                    
                    [sorted,order] = sort(vertcat(predictionList.Output),'descend');
                    
                    obj.ReviewData.order = order;
                    obj.ReviewData.filterSettings = PostSettings;
                    
                end
                %
                %
                %         %----two leads
                %             if length(thisPair)==2
                %                 printtext(fileID,'\t\t\t%s\t%s\n',obj.VTAs(1).ActorElectrode.Tag,obj.VTAs(2).ActorElectrode.Tag);
                %                 printtext(fileID,'-------------------------------------------\n')
                %                 for iShortlist = 1:length(order)
                %                     item = order(iShortlist);
                %                     Improv = predictionList(item).Output;
                %                     c_e1 = predictionList(item).Input.VTAs(1).Settings.activecontact;
                %                     c_e2 = predictionList(item).Input.VTAs(2).Settings.activecontact;
                %                     a_e1 = predictionList(item).Input.VTAs(1).Settings.amplitude;
                %                     a_e2 = predictionList(item).Input.VTAs(2).Settings.amplitude;
                %                     conf_e1 = predictionList(item).Confidence(1);
                %                     conf_e2 = predictionList(item).Confidence(2);
                %
                %                     printtext(fileID,'%i.\t %2.1f \t C%i - %2.1f mA\t C%i - %2.1f mA \t (%2.2f / %2.2f) \n',iShortlist,Improv, c_e1,a_e1,c_e2,a_e2,conf_e1,conf_e2);
                %
                %                 end
                %             else
                %
                %     %----one lead
                %                 for iShortlist = 1:length(order)
                %                     %                 thisPair = ReviewData.pairs(order(iShortlist),:);
                %                     item = order(iShortlist);
                %                     Improv = predictionList(item).Output;
                %                     c_e1 = predictionList(item).Input.VTAs(1).Settings.activecontact;
                %                     a_e1 = predictionList(item).Input.VTAs(1).Settings.amplitude;
                %                     conf_e1 = predictionList(item).Confidence(1);
                %
                %                     printtext(fileID,'%i.\t %2.1f \t C%i - %2.1f mA\t (%2.2f) \n',iShortlist,Improv, c_e1,a_e1,conf_e1);
                %
                %                 end
                %             end
                %
                %             fclose(fileID);
                
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
        
        function sortedPredictionList = sortImproConf(obj,predictionList) %this function sorts out low confidences, orders in respect to confidence and impro
            
            if ~numel(predictionList)
                sortedPredictionList = [];
            else
                
                highConf = min(vertcat(predictionList(:).Confidence)')>0.85;
                TopConfList = predictionList(highConf);
                
                lowConf = min(vertcat(predictionList(:).Confidence)')>0.55;
                LowConfList = predictionList(lowConf);
                
                if numel(TopConfList)>1
                    
                    [~,orderTop] = sort(vertcat(TopConfList.Output),'descend');
                    orderTop = orderTop';
                    TopConfList = TopConfList(orderTop(:));
                    
                    
                end
                
                ConfSum = sum(vertcat(LowConfList(:).Confidence),2);
                
                [~,orderLow] = sort(vertcat(LowConfList(:).Output).*ConfSum);
                orderLow = orderLow';
                LowConfList = LowConfList(orderLow(:));
                
                sortedPredictionList = horzcat(TopConfList,LowConfList);
                
            end
            
            
        end
        
        function AlternativeSettings = reduceSE(obj,predictionList) %finds alternatives to reduce side effects
            
            % first constructs indeces based on contact position and
            % ampitude in respect to reccommended settings
            
            for iList = 1:numel(predictionList)
                
                leftProx = zeros(1,iList);
                rightProx = zeros(1,iList);
                leftLowAmp = zeros(1,iList);
                rightLowAmp = zeros(1,iList);
                left_Prox = zeros(1,iList);
                right_Prox = zeros(1,iList);
                left_LowAmp = zeros(1,iList);
                right_LowAmp = zeros(1,iList);
                
                
                leftProx(iList) = predictionList(iList).Input.VTAs(1,1).Settings.activecontact...
                    > obj.RecommendedSettings.Input.VTAs(1,1).Settings.activecontact;
                
                rightProx(iList) = predictionList(iList).Input.VTAs(1,2).Settings.activecontact...
                    > obj.RecommendedSettings.Input.VTAs(1,2).Settings.activecontact;
                
                leftLowAmp(iList) = (predictionList(iList).Input.VTAs(1,1).Settings.amplitude...
                    - obj.RecommendedSettings.Input.VTAs(1,1).Settings.amplitude) < 1;
                
                rightLowAmp(iList) = (predictionList(iList).Input.VTAs(1,2).Settings.amplitude...
                    - obj.RecommendedSettings.Input.VTAs(1,2).Settings.amplitude) < 1;
                
                left_Prox(iList) = predictionList(iList).Input.VTAs(1,1).Settings.activecontact...
                    >= obj.RecommendedSettings.Input.VTAs(1,1).Settings.activecontact;
                
                right_Prox(iList) = predictionList(iList).Input.VTAs(1,2).Settings.activecontact...
                    >= obj.RecommendedSettings.Input.VTAs(1,2).Settings.activecontact;
                
                left_LowAmp(iList) = (predictionList(iList).Input.VTAs(1,1).Settings.amplitude...
                    - obj.RecommendedSettings.Input.VTAs(1,1).Settings.amplitude) < 0.5;
                
                right_LowAmp(iList) = (predictionList(iList).Input.VTAs(1,2).Settings.amplitude...
                    - obj.RecommendedSettings.Input.VTAs(1,2).Settings.amplitude) < 0.5;
                
            end
            
            Prox = leftProx&rightProx;
            LowAmp = leftLowAmp&rightLowAmp;
            filter1 = Prox&LowAmp;
            
            filterL = leftProx&leftLowAmp;
            filterR = rightProx&rightLowAmp;
            filterAmp = (left_LowAmp&right_LowAmp)&(left_Prox&right_Prox);
            
            %if there is a settigns with proximal contacts bilat take it
            if numel(obj.sortImproConf(predictionList(filter1))) > 0
                filtered=obj.sortImproConf(predictionList(filter1));
                AlternativeSettings.universal=filtered(1,1);
                
            else % if not, do it for sides separately
                
                AlternativeSettings.universal = {'Universal side effects reducing settings not found'};
                
                if numel(obj.sortImproConf(predictionList(filterL))) > 0
                    filteredL = obj.sortImproConf(predictionList(filterL));
                    AlternativeSettings.leftHemisphereSE = filteredL(1,1);
                else
                    AlternativeSettings.leftHemisphereSE = {'Alternative settings for left hemisphere side effects not found'};
                    
                end
                
                if numel(obj.sortImproConf(predictionList(filterR))) > 0
                    filteredR = sortIproConf(predictionList(filterR));
                    AlternativeSettings.rightHemisphereSE = filteredR(1,1);
                else
                    AlternativeSettings.rightHemisphereSE = {'Alternative settings for right hemisphere side effects not found'};
                    
                end
                
            end
            
            % take best settings with lower amp
            if numel(obj.sortImproConf(predictionList(filterAmp))) > 0
                filteredAmp = obj.sortImproConf(predictionList(filterAmp));
                AlternativeSettings.ampReduction = filteredAmp(1,1);
                
            else
                
                AlternativeSettings.ampReduction = {'Alternative settings with reduced amplitude not found, reduce amplitude of recommended settings manually'};
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
        function UserChoices = UserInputModule()
            %ask for heatmap/model
            global predictionmanager
            heatmap = predictionmanager.selectHeatmap();
            
            %Ask for mode
            options = {'60 us - 1,2,3,4,5 mA - MDT3389',...
                '60 us - 0.1mA steps - MDT3389',...
                '60 us - 0.5 mA steps - MDT3389',...
                '60 us - just 2.5 mA - MDT3389',...
                '120 us - 0.5 mA steps - MDT3389',...
                '60 us - just 2 and 4 mA- MDT3389',...
                '60 us - 3.2 mA steps - MDT3389 (cogn. decline monopolar review)'};
            
            answer = listdlg('PromptString','Select monopolar review preset (can be updated in Therapy.m):','ListString',options,'ListSize',[400,100]);
            VTAset = options{answer};
            
            %Ask for postprocessing filter settings. (heatmap specific)
            PostSettings = heatmap.definePostProcessingSettings();
            
            UserChoices.heatmap = heatmap;
            UserChoices.VTAset = VTAset;
            UserChoices.PostSettings = PostSettings;
        end
    end
    
    
end


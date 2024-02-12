function [popupdata] = createPopup(therapyList,filename)

popupdata.model1name = '1';
popupdata.model2name = '2';

% Get monitor dimensions
monitorSize = get(0,'ScreenSize');
monitorWidth = monitorSize(3);
monitorHeight = monitorSize(4);

% Create figure
f = figure('Name', filename, 'Position', [monitorWidth/3, 0, monitorWidth/1.5, monitorHeight]);


dropdownWidth = 0.4;

% Create dropdown 1
dropdown1 = uicontrol('Style', 'pushbutton', 'String', 'Select model...',...
    'Units', 'normalized', 'Position', [0.05, 0.9, dropdownWidth, 0.05],'Callback',@model1);

% Create dropdown 2
dropdown2 = uicontrol('Style', 'pushbutton', 'String', 'Select model...',...
    'Units', 'normalized', 'Position', [0.55, 0.9, dropdownWidth, 0.05],'Callback',@model2,'Enable','off');

popupdata.dropdown2 = dropdown2;

% Create panel for radio buttons 1
panel1 = uipanel('Title', '', 'Position', [0.05, 0.8, dropdownWidth, 0.08]);

% Create radio buttons for panel 1
radioGroup1 = uibuttongroup('Parent', panel1, 'Units', 'normalized', 'Position', [0, 0, 1, 1]);
%radio1 = uicontrol(radioGroup1, 'Style', 'radiobutton', 'String', 'Highest', 'Units', 'normalized', 'Position', [0.05, 0.75, 0.4, 0.2]);
radio2 = uicontrol(radioGroup1, 'Style', 'radiobutton', 'String', 'Higher or equal', 'Units', 'normalized', 'Position', [0.05, 0.75, 0.9, 0.2]);
%radio3 = uicontrol(radioGroup1, 'Style', 'radiobutton', 'String', 'Lowest', 'Units', 'normalized', 'Position', [0.05, 0.5, 0.4, 0.2]);
radio4 = uicontrol(radioGroup1, 'Style', 'radiobutton', 'String', 'Lower or equal', 'Units', 'normalized', 'Position', [0.05, 0.5, 0.9, 0.2]);

% Create panel for radio buttons 1
panel2 = uipanel('Title', '', 'Position', [0.55, 0.8, dropdownWidth, 0.08]);

% Create radio buttons for panel 1
radioGroup2 = uibuttongroup('Parent', panel2, 'Units', 'normalized', 'Position', [0, 0, 1, 1]);
radio5 = uicontrol(radioGroup2, 'Style', 'radiobutton', 'String', 'Highest', 'Units', 'normalized', 'Position', [0.05, 0.75, 0.4, 0.2]);
radio6 = uicontrol(radioGroup2, 'Style', 'radiobutton', 'String', 'Highest (no compromise)', 'Units', 'normalized', 'Position', [0.55, 0.75, 0.4, 0.2]);
radio7 = uicontrol(radioGroup2, 'Style', 'radiobutton', 'String', 'Lowest', 'Units', 'normalized', 'Position', [0.05, 0.5, 0.4, 0.2]);
radio8 = uicontrol(radioGroup2, 'Style', 'radiobutton', 'String', 'Lower (no compromise)', 'Units', 'normalized', 'Position', [0.55, 0.5, 0.4, 0.2]);

%table
tableHandle = uitable(f, 'Units', 'normalized', 'Position', [0.1, 0.05, 0.8, 0.6]);

% Create SAVE
save = uicontrol('Style', 'pushbutton', 'String', 'Export table to excel...',...
    'Units', 'normalized', 'Position', [0.1, 0.02, 0.8, 0.05],'Callback',@export);


buttonWidth = 0.8;
button = uicontrol('Style', 'pushbutton', 'String', 'Run review for optimization', ...
    'Units', 'normalized', 'Position', [0.1, 0.7, buttonWidth, 0.05],'Callback', {@run,tableHandle});

initiateTable();

%--- functions
% Define dropdown options function
    function options = model1(hObject,eventdata)
        settings = Therapy.UserInputModule;
        name = [class(settings.heatmap),' // ',settings.VTAset];
        hObject.String = name;
        
        popupdata.dropdown2.Enable = 'on';
        popupdata.model1 = settings;
        popupdata.model1name = class(settings.heatmap);
         updateTable
        
    end

    function options = model2(hObject,eventdata)
        
        preset = popupdata.model1;
        preset.heatmap = [];
        preset.PostSettings = [];
        
        settings = Therapy.UserInputModule(preset);
        
        name = [class(settings.heatmap),' // ',settings.VTAset];
        hObject.String = name;
        
        popupdata.model2 = settings;
        popupdata.model2name = class(settings.heatmap);
         updateTable
        
    end

    function export(hObject,eventdata)
        folder = '/Users/jonas/Documents/MATLAB/ArenaToolbox/ArenaToolbox/UserData';
        writetable(popupdata.table,fullfile(folder,['analysis_for_',filename]),'WriteRowNames',true)
    end


    function initiateTable()
        therapyNames = {therapyList.Tag}';
        rownames = therapyNames;
        columnnames = {['prediction_',popupdata.model1name],['prediction_',popupdata.model2name],['suggestion_',popupdata.model1name],['suggestion_',popupdata.model2name],'number_of_candidates','number_of_options'};
        data = nan([numel(rownames),numel(columnnames)]);
        popupdata.table = array2table(data,'VariableNames',columnnames,'RowNames',rownames);
        popupdata.therapyList = therapyList;

        set(tableHandle, 'RowName', popupdata.table.Properties.RowNames,'ColumnName',popupdata.table.Properties.VariableNames,'Data',popupdata.table{:,:});
        
    end



    function run(hObject,eventdata,tableHandle)

        for iTherapy = 1:length(popupdata.therapyList)
            
            prediction_1 = ['prediction_',popupdata.model1name];
            prediction_2 = ['prediction_',popupdata.model2name];
            
            %-----
            % Step 1. run a prediction to know the reference values
            thisTherapy = popupdata.therapyList(iTherapy);
            outcome_1 = thisTherapy.executePrediction(popupdata.model1.heatmap);
            outcome_2 = thisTherapy.executePrediction(popupdata.model2.heatmap);
            popupdata.table.(prediction_1)(iTherapy) = outcome_1.Output;
            popupdata.table.(prediction_2)(iTherapy) = outcome_2.Output;
            updateTable()
            
            
            
            %----
            % Step 2. Run a monopolar review for the first model and filter
            % based on the user setting.
            
            thisTherapy = popupdata.therapyList(iTherapy);
            review_1 = thisTherapy.executeReview(popupdata.model1);
            
            review_1_scores = [review_1.ReviewData.predictionList.Output];
            reference = popupdata.table.(prediction_1)(iTherapy);
            
            %if radio1.Value
            %    indx = review_1_scores == max(review_1_scores);
           if radio2.Value
                indx = review_1_scores >= reference;
            %elseif radio3.Value
              %  indx = review_1_scores == min(review_1_scores);
            elseif radio4.Value
                indx = review_1_scores <= reference;
            end
            
            
            TherapyCandidates = review_1.ReviewData.predictionList(indx);
            popupdata.table.number_of_candidates(iTherapy) = sum(indx);
            updateTable();
            
            %----
            % Step 3. Use the left over candidates to test the second
            % model. Then filter those based on user settings.
            
            review2 = [];
            for iCandidate = 1:numel(TherapyCandidates)
                thisCandidate = TherapyCandidates(iCandidate);
                t = Therapy;
                t.VTAs = thisCandidate.Input.VTAs;
                t.executePrediction(popupdata.model2.heatmap);
                
                prediction2 = t.Predictions.Output;
                
               review2(iCandidate) = prediction2;
            end
            
            summaryStep1 = review_1_scores(indx);
            
            if radio5.Value
                winners = review2==max(review2);
                %notWorse  = review2 >= outcome_2;
                %winners = and(winners,notWorse);
            elseif radio7.Value
                winners = review2==min(review2);
                %notWorse = review2 <= outcome_2.Output;
                %winners = and(winners,notWorse);
            end
            popupdata.table.number_of_options(iTherapy) = sum(winners);
            
            %---
            % Step 4. Save the data
            suggestion_1 = ['suggestion_',popupdata.model1name];
            suggestion_2 = ['suggestion_',popupdata.model2name];
            
            if sum(winners)>=1
                winner = find(winners,1);
                popupdata.table.(suggestion_1)(iTherapy) = TherapyCandidates(winner).Output;
                popupdata.table.(suggestion_2)(iTherapy) = review2(winner);
                popupdata.candidates{iTherapy}.candidates = TherapyCandidates(winners);
                popupdata.candidates{iTherapy}.best = TherapyCandidates(winner);
                
                popupdata.candidates{iTherapy}.model1 = summaryStep1(winners);
                 popupdata.candidates{iTherapy}.model2 = review2(winners);
                
                
            elseif sum(winners) == 0 %no candidates
                popupdata.table.suggestion_1(iTherapy) = nan;
                popupdata.table.suggestion_2(iTherapy) = nan;
                
            end
            
               
            
            export(hObject,eventdata)
        end
        
   updateTable
       
    end

    function updateTable
        columnnames = {['prediction_',popupdata.model1name],['prediction_',popupdata.model2name],['suggestion_',popupdata.model1name],['suggestion_',popupdata.model2name],'number_of_candidates','number_of_options'};
        popupdata.table.Properties.VariableNames = columnnames;
        set(tableHandle,'Data',popupdata.table{:,:},'ColumnName',columnnames)
        drawnow()
    end
    
end
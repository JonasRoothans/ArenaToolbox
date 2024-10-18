function [popupdata] = createPopup(therapyList,filename)

popupdata.model1name = '1';
popupdata.model2name = '2';
popupdata.syncedWithExcelSheet = nan;
popupdata.filename = filename;

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
button_cohort = uicontrol('Style', 'pushbutton', 'String', 'Run review for optimization for this Cohort', ...
    'Units', 'normalized', 'Position', [0.1, 0.7, buttonWidth*0.45, 0.05],'Callback', {@run,tableHandle});
button_single = uicontrol('Style', 'pushbutton', 'String', 'Run review for optimization for one case', ...
    'Units', 'normalized', 'Position', [0.1+buttonWidth*0.55, 0.7, buttonWidth*0.45, 0.05],'Callback', {@run_one,tableHandle});
uicontrol('Style','text','String','..or..','Units','normalized','Position',[0.1+buttonWidth*0.45, 0.7-0.025, 0.1*buttonWidth, 0.05])

buttonstartindx = uicontrol('Style', 'popupmenu', 'String', [{'Start at..',},{therapyList.Tag}], ...
    'Units', 'normalized', 'Position', [0.7, 0.65, buttonWidth/4, 0.05]);

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
         updateTable()
         syncTable()
        
    end


    function export(hObject,eventdata)
        [fol,fil] = generateFileName();
        writetable(popupdata.table,fullfile(fol,fil),'WriteRowNames',true)
    end

    function [foldername,filename] = generateFileName()
        global arena
        foldername = fullfile(arena.Settings.rootdir,'UserData');
        filename = ['analysis_for_','_',popupdata.model1name,'_',popupdata.model2name,'_',popupdata.model1.VTAset,'_',popupdata.filename];
    end
        


    function initiateTable()
        therapyNames = {therapyList.Tag}';
        rownames = therapyNames;
        columnnames = {['prediction_',popupdata.model1name],['prediction_',popupdata.model2name],['suggestion_',popupdata.model1name],['suggestion_',popupdata.model2name],'number_of_candidates','number_of_options',['e1_Optimal_contact_',popupdata.model1name],['e1_Optimal_amp_',popupdata.model1name],['e2_Optimal_contact_',popupdata.model1name],['e2_Optimal_amp_',popupdata.model1name],'e1','e2',['best_score_for_1',popupdata.model1name]};

        data = nan([numel(rownames),numel(columnnames)]);
        popupdata.table = array2table(data,'VariableNames',columnnames,'RowNames',rownames);
        popupdata.therapyList = therapyList;

        set(tableHandle, 'RowName', popupdata.table.Properties.RowNames,'ColumnName',popupdata.table.Properties.VariableNames,'Data',popupdata.table{:,:});
        
    end
    
    function main_engine(iTherapy)
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
            
            
            
            %----         % Step 2. Run a monopolar review for the first model and filter
            % based on the user setting.
            
            thisTherapy = popupdata.therapyList(iTherapy);
            review_1 = thisTherapy.executeReview(popupdata.model1);
            
            review_1_scores = [review_1.ReviewData.predictionList.Output];
            reference = popupdata.table.(prediction_1)(iTherapy);
            
            %if radio1.Value
            %    indx = review_1_scores == max(review_1_scores);
           if radio2.Value
                indx = review_1_scores >= reference;
                [best_1, indx_best_1] = max(review_1_scores);
            %elseif radio3.Value
              %  indx = review_1_scores == min(review_1_scores);
            elseif radio4.Value
                indx = review_1_scores <= reference;
                [best_1, indx_best_1] = min(review_1_scores);
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
            
            %export best settings based on SOLELY model 1
            suggestion_1 = ['suggestion_',popupdata.model1name];
            suggestion_2 = ['suggestion_',popupdata.model2name];
            optimal_1_contact_1 = ['e1_Optimal_contact_',popupdata.model1name];
            optimal_1_amp_1 = ['e1_Optimal_amp_',popupdata.model1name];
            optimal_1_contact_2 = ['e2_Optimal_contact_',popupdata.model1name];
            optimal_1_amp_2 = ['e2_Optimal_amp_',popupdata.model1name];
            best_score_for_1 = ['best_score_for_1',popupdata.model1name];
            
            popupdata.table.(optimal_1_contact_1)(iTherapy) = review_1.ReviewData.predictionList(indx_best_1).Input.VTAs(1).Settings.activecontact;
            popupdata.table.(optimal_1_amp_1)(iTherapy) = review_1.ReviewData.predictionList(indx_best_1).Input.VTAs(1).Settings.amplitude;
            popupdata.table.(optimal_1_contact_2)(iTherapy) = review_1.ReviewData.predictionList(indx_best_1).Input.VTAs(2).Settings.activecontact;
            popupdata.table.(optimal_1_amp_2)(iTherapy) = review_1.ReviewData.predictionList(indx_best_1).Input.VTAs(2).Settings.amplitude;
            popupdata.table.(best_score_for_1)(iTherapy) = best_1;
            
            if review_1.VTAs(1).Electrode.C0.x >0
                e1side = 'R';
            else
                e1side = 'L';
            end
            if review_1.VTAs(2).Electrode.C0.x > 0
                e2side = 'R';
            else
                e2side = 'L';
            end
            popupdata.table.e1(iTherapy) = e1side;
             popupdata.table.e2(iTherapy) = e2side;
            
            if sum(winners)>=1
                winner = find(winners,1);
                popupdata.table.(suggestion_1)(iTherapy) = TherapyCandidates(winner).Output;
                popupdata.table.(suggestion_2)(iTherapy) = review2(winner);
                popupdata.candidates{iTherapy}.candidates = TherapyCandidates(winners);
                popupdata.candidates{iTherapy}.best = TherapyCandidates(winner);
                
                popupdata.candidates{iTherapy}.model1 = summaryStep1(winners);
                 popupdata.candidates{iTherapy}.model2 = review2(winners);
                
                
            elseif sum(winners) == 0 %no candidates
                popupdata.table.(suggestion_1)(iTherapy) = nan;
                popupdata.table.(suggestion_2)(iTherapy) = nan;
                
            end
            
               
            
            export(hObject,eventdata)
    end

    function run_one(hObject,eventdata,tablehandle)
        if buttonstartindx.Value==1
            %no selection was made, so we assume the first patient should
            %be done
            i = 1;
        else
            i = buttonstartindx.Value-1;
        end

        main_engine(i)
        updateTable

        %--- Print all details now
        

    end



    function run(hObject,eventdata,tableHandle)
        
        
        startindex = buttonstartindx.Value-1;
        startindex(startindex<1) = 1;
        for iTherapy = startindex:length(popupdata.therapyList)
            main_engine(iTherapy)
        end
        
   updateTable
       
    end

    function updateTable()
        columnnames = {['prediction_',popupdata.model1name],['prediction_',popupdata.model2name],['suggestion_',popupdata.model1name],['suggestion_',popupdata.model2name],'number_of_candidates','number_of_options',['e1_Optimal_contact_',popupdata.model1name],['e1_Optimal_amp_',popupdata.model1name],['e2_Optimal_contact_',popupdata.model1name],['e2_Optimal_amp_',popupdata.model1name],'e1','e2',['best_score_for_1',popupdata.model1name]};
        popupdata.table.Properties.VariableNames = columnnames;
        set(tableHandle,'Data',popupdata.table{:,:},'ColumnName',columnnames)
        drawnow()
    end

    function syncTable()
        [fol,fil] = generateFileName();
        if exist(fullfile(fol,fil),'file')
            Tread = readtable(fullfile(fol,fil));
            popupdata.table = Tread(1:end,2:end); %strip the row column
            
            buttonstartindx.Value = find(isnan(Tread.e1),1)+1;
            buttonstartindx.ForegroundColor = [1 0 0];
            %sync
            keyboard
            updateTable
        end
            
        
    end
    
end
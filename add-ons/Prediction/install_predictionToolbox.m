function install_predictionToolbox(hObject,eventdata,Scene)
%This function installs all necessary components for using the prediction
%toolbox originally concepted by Jonas Roothans,MSc. and redesigned plus
%extended by Tim Wichmann(biomedical engineering student at htw saar)
Scene=getpredictdata(hObject);
Scene.handles.dynamicHeadClasses{(numel(Scene.handles.dynamicHeadClasses))+1}='predict';
Scene.handles.text_box_listSelectResult = uicontrol('parent',Scene.handles.figure,...
    'style','text',...
    'units','normalized',...
    'position', [0.02,0.43,0.1,0.2],...
    'String','All results which were found...',...
    'Visible','off');

Scene.handles.box_listSelectResult = uicontrol('parent',Scene.handles.figure,...
    'style','listbox',...
    'units','normalized',...
    'position', [0.02,0.4,0.11,0.2],...
    'String',{},...
    'Visible','off');

Scene.handles.confirmbutton_box_listSelectResult = uicontrol('parent',Scene.handles.figure,...
    'units','normalized',...
    'position',[0.02,0.37,0.11,0.03],...
    'String','Show Result',...
    'Visible','off',...
    'callback',{@confirmbutton_box_listSelectResult});

Scene.handles.closebutton_box_listSelectResult = uicontrol('parent',Scene.handles.figure,...
    'units','normalized',...
    'position',[0.12,0.60,0.01,0.03],...
    'String','X',...
    'Visible','off',...
    'callback',{@menu_closePredictionWindow});

Scene.handles.panel_showResults=patch('Parent',Scene.handles.axes,'XData',[-1000 -1000 1000 1000],...
    'YData',[0 0 0 0],...
    'ZData',[-1000 1000 1000 -1000],...
    'FaceAlpha',0.2,...
    'FaceColor',[1 1 1],...
    'Visible','off');

Scene.handles.closebutton_panel_showResults = uicontrol('parent',Scene.handles.figure,...
    'units','normalized',...
    'position',[0.9,0.9,0.07,0.1],...
    'FontSize',18,...
    'String','X',...
    'Visible','off',...
    'callback',{@closebutton_panel_closeShowResults});

Scene.handles.menu.dynamic.predict.main = uimenu(Scene.handles.menu.dynamic.main ,'Text','Prediction');

Scene.handles.menu.dynamic.Electrode.loadedLeadBasedCalculation = uimenu(Scene.handles.menu.dynamic.predict.main,'Text','Electrode:Open Prediction Enviroment','Callback',{@menu_openPredictionEnviroment},'Enable','off');
Scene.handles.menu.dynamic.Electrode.randomDataBasedcalculation = uimenu(Scene.handles.menu.dynamic.predict.main,'Text','Electrode:Run a prediction without preloaded data','Callback',{@menu_runPredictionWithoutPreloadedData});
Scene.handles.menu.dynamic.Electrode.results = uimenu(Scene.handles.menu.dynamic.predict.main,'Text','Electrode:View Results','Callback',{@menu_viewActorResults},'Enable','off');
Scene.handles.menu.dynamic.Electrode.close = uimenu(Scene.handles.menu.dynamic.predict.main,'Text','Electrode:Close Result Window','Callback',{@menu_closePredictionWindow},'Enable','off');
Scene.handles.menu.dynamic.Electrode.showOldResults = uimenu(Scene.handles.menu.dynamic.predict.main,'Text','Electrode:Show old Results','Callback',{@menu_showOldResults},'Enable','off');
Scene.handles.menu.dynamic.Mesh.getPredictionValue=uimenu(Scene.handles.menu.dynamic.analyse.main,'Text','Mesh: Get Prediction Value for ','callback',{@menu_getPredictionValue},'Enable','off');

    function menu_getPredictionValue(hObject,eventdata)
        
        scene = ArenaScene.getscenedata(hObject);
        selection=scene.handles.panelright.Value(1,1);
        if ismember(';',scene.Actors(1,selection).Tag)
            scene.Actors(1,selection).Tag=scene.Actors(1,selection).Tag(1:end-8);
        end
        try
            selection=scene.handles.panelright.Value(1,2);
            error('You selected to many VTAs! Only one is allowed!');
        catch
            
            try
                for i=1:numel(scene.Actors)
                    try
                        C0=scene.Actors(1,i).Data.C0.x;
                        if scene.Actors(1,selection).C0(1,1)==C0 && scene.Actors(1,selection).NumberOfLead==scene.Actors(1,i).NumberOfLead
                            if scene.Actors(1,selection).C0(1,1)<0
                                scene.Actors(1,selection).Tag=[scene.Actors(1,selection).Tag,';',num2str(scene.Actors(1,i).PredictInformation.handles.prediction_Information.unilateral.leftVTAPrediction)];
                                break;
                            else
                                scene.Actors(1,selection).Tag=[scene.Actors(1,selection).Tag,';',num2str(scene.Actors(1,i).PredictInformation.handles.prediction_Information.unilateral.rightVTAPrediction)];
                                break;
                            end
                        end
                    catch
                    end
                end
                scene.refreshLayers();
            catch
                error('No calculated prediction value was found for this VTA! Please check, wheter you already did the prediction on the referenced lead!');
            end
        end
    end

    function menu_openPredictionEnviroment(hObject,eventdata)
        thisScene=ArenaScene.getscenedata(hObject);
        thisScene.handles.menu.file.predict.close.Enable='off';
        thisScene.handles.menu.file.predict.results.Enable='off';
        
        if numel(thisScene.handles.panelright.Value)<3 && numel(thisScene.handles.panelright.Value)>0
            selection=thisScene.handles.panelright.Value(1,1);
            PathDirectory=thisScene.Actors(1,selection).PathDirectory;
            thisScene.Actors(1,selection).PredictInformation=predictFuture();
            try
                selection2=thisScene.handles.panelright.Value(1,2);
                %----
                % for bilateral predictions
                if strcmp(thisScene.Actors(1,selection).PathDirectory,thisScene.Actors(1,selection2).PathDirectory)
                    if isa(thisScene.Actors(1,selection2).Data,'Electrode')
                        selected=thisScene.Actors(1,selection).Data.C0.x>0;
                        maybeMatching=thisScene.Actors(1,selection2).Data.C0.x>0;
                        if selected~=maybeMatching
                            thisScene.Actors(1,selection).PredictInformation.bilateralOn=1;
                            thisScene.Actors(1,selection).PredictInformation.config.SecondLead=thisScene.Actors(1,selection2).Data;
                            thisScene.Actors(1,selection).PredictInformation.config.SecondLead.NumberOfLead=thisScene.Actors(1,selection2).NumberOfLead;
                            waitfor(msgbox('Your bilateral prediction data will be stored under the name coming first in the panel on the right...'));
                        end
                    end
                end
            catch
                disp('Unilateral prediction will be done!');
            end
            % for unilateral prediction
            thisScene.Actors(1,selection).PredictInformation.config.FirstLead=thisScene.Actors(1,selection).Data;
            thisScene.Actors(1,selection).PredictInformation.config.FirstLead.NumberOfLead=thisScene.Actors(1,selection).NumberOfLead;
            thisScene.Actors(1,selection).PredictInformation.Tag=thisScene.Actors(1,selection).Tag;
            thisScene.Actors(1,selection).PredictInformation.newPrediction(PathDirectory);
            % when prediction is finished the Results should be
            % shown and also accessed
            try
                waitfor(thisScene.Actors(1,selection).PredictInformation.handles.figure);
                if isempty(thisScene.Actors(1,selection).PredictInformation.Heatmap)
                    warning('No Prediction Data was calculated!');
                else
                    thisScene.Actors(1,selection).PredictInformation.Results={thisScene.Actors(1,selection).PredictInformation.handles.prediction_Information,thisScene.Actors(1,selection).PredictInformation.Heatmap,...
                        thisScene.Actors(1,selection).PredictInformation.configStructure};
                    thisScene.Actors(1,selection).Tag=thisScene.Actors(1,selection).PredictInformation.Tag;
                end
                
                if isa(thisScene.Actors(1,selection).PredictInformation.Results,'cell')
                    menu_viewActorResults(thisScene);
                end
            catch
                return
            end
        else
            error('You selected too many leads!');
        end
    end

    function menu_runPredictionWithoutPreloadedData(hObject,eventdata)
        thisScene=ArenaScene.getscenedata(hObject);
        PathDirectory=0;
        lead=PredictionActor();
        lead.PredictInformation=predictFuture();
        lead.PredictInformation.newPrediction(PathDirectory);
        try
            waitfor(lead.PredictInformation.handles.figure);
        catch
            return
        end
        try
            if isempty(lead.PredictInformation.Heatmap)
                warning('No Prediction Data was calculated!');
            end
        catch
            return
        end
        warning('If you want to display this results, please use the "Show old results" submenu!');
        lead.delete();
        thisScene.handles.menu.dynamic.Electrode.showOldResults.Enable='on';
    end

    function menu_viewActorResults(hObject,eventdata)
        if not(isa(hObject,'ArenaScene'))
            thisScene=ArenaScene.getscenedata(hObject);
        else
            thisScene=hObject;
        end
        thisScene.handles.text_box_listSelectResult.Visible ='on';
        thisScene.handles.menu.dynamic.Electrode.showOldResults.Enable='on';
        thisScene.handles.menu.dynamic.Electrode.close.Enable='on';
        thisScene.handles.confirmbutton_box_listSelectResult.Visible='on';
        thisScene.handles.closebutton_box_listSelectResult.Visible='on';
        listSelectResultEnd=numel(thisScene.handles.panelright.String);
        thisScene.handles.box_listSelectResult.String={};
        thisScene.handles.box_listSelectResult.UserData=struct();
        for irepetitions=1:listSelectResultEnd
            try
                if isa(thisScene.Actors(1,irepetitions).PredictInformation.Results,'cell')
                    elementsOfString=numel(thisScene.handles.box_listSelectResult.String);
                    if elementsOfString==0
                        elementsOfString=1;
                    else
                        elementsOfString=elementsOfString+1;
                    end
                    thisScene.handles.box_listSelectResult.String{elementsOfString}=thisScene.Actors(1,irepetitions).Tag;
                    thisScene.handles.box_listSelectResult.UserData(1,elementsOfString).Number=irepetitions;
                end
            catch
            end
        end
        thisScene.handles.box_listSelectResult.Visible='on';
    end

    function confirmbutton_box_listSelectResult(hObject,eventdata)
        thisScene=ArenaScene.getscenedata(hObject);
        if not(isempty(thisScene.handles.box_listSelectResult.Value))
            box_listSelectResult(thisScene);
        end
    end

    function box_listSelectResult(thisScene)
        displayDecision=thisScene.handles.box_listSelectResult.Value;
        displayDecision=thisScene.handles.box_listSelectResult.UserData(1,displayDecision).Number;
        if not(isempty(displayDecision))
            d=predictResults();
            set(thisScene.handles.menu.addons.main,'Enable','off');
            set(thisScene.handles.menu.file.main,'Enable','off');
            set(thisScene.handles.menu.stusessions.main,'Enable','off');
            set(thisScene.handles.menu.view.main,'Enable','off');
            set(thisScene.handles.menu.atlas.main,'Enable','off');
            set(thisScene.handles.menu.edit.main,'Enable','off');
            set(thisScene.handles.menu.transform.main,'Enable','off');
            set(thisScene.handles.menu.dynamic.main,'Enable','off');
            set(thisScene.handles.btn_toggleleft,'Enable','off','Visible','off');
            set(thisScene.handles.btn_toggleright,'Enable','off','Visible','off');
            set(thisScene.handles.panelleft,'Visible','off');
            set(thisScene.handles.panelright,'Visible','off');
            set(thisScene.handles.btn_layeroptions,'Visible','off');
            set(thisScene.handles.menu.view.camera.orthogonal.coronal,'Text','coronal plane');
            ypos=campos;
            set(thisScene.handles.figure,'CurrentAxes',thisScene.handles.axes);
            campos('manual');
            notify(thisScene.handles.menu.view.camera.orthogonal.coronal,'Action');
            thisScene.handles.closebutton_panel_showResults.Visible='on';
            notify(thisScene.handles.closebutton_box_listSelectResult,'Action');
            thisScene.handles.unusableButton=uicontrol('Visible','off','Enable','off');
            thisScene.handles.unusableButton.Callback=thisScene.handles.figure.WindowKeyPressFcn;
            thisScene.handles.unusableButton.CreateFcn=thisScene.handles.figure.WindowButtonMotionFcn;
            thisScene.handles.figure.WindowScrollWheelFcn =[];
            thisScene.handles.figure.WindowButtonDownFcn=[];
            thisScene.handles.figure.WindowButtonUpFcn=[];
            thisScene.handles.figure.WindowKeyPressFcn=[];
            thisScene.handles.figure.WindowButtonMotionFcn=[];  
            set(thisScene.handles.panel_showResults,'Visible','on');
            set(thisScene.handles.panel_showResults,'UserData',ypos);
            set(thisScene.handles.panel_showResults,'YData',[ypos(1,2)-50 ypos(1,2)-50 ypos(1,2)-50 ypos(1,2)-50]);
            d.displayHighestResults(thisScene,displayDecision);
        else
            error('No Prediction Data was found!');
        end
    end

    function closebutton_panel_closeShowResults(hObject,eventdata)
        thisScene=ArenaScene.getscenedata(hObject);
        thisScene.handles.closebutton_panel_showResults.Visible='off';
        ypos=thisScene.handles.panel_showResults.UserData;
        thisScene.handles.panel_showResults.Visible='off';
        A_mouse_camera(thisScene.handles.figure);
        thisScene.handles.figure.WindowKeyPressFcn=thisScene.handles.unusableButton.Callback;
        thisScene.handles.figure.WindowButtonMotionFcn=thisScene.handles.unusableButton.CreateFcn;
        set(thisScene.handles.btn_toggleleft,'Enable','on','Visible','on');
        set(thisScene.handles.btn_toggleright,'Enable','on','Visible','on');
        set(thisScene.handles.panelleft,'Visible','on');
        set(thisScene.handles.panelright,'Visible','on');
        set(thisScene.handles.btn_layeroptions,'Visible','on');
        set(thisScene.handles.menu.file.main,'Enable','on');
        set(thisScene.handles.menu.stusessions.main,'Enable','on');
        set(thisScene.handles.menu.view.main,'Enable','on');
        set(thisScene.handles.menu.atlas.main,'Enable','on');
        set(thisScene.handles.menu.edit.main,'Enable','on');
        set(thisScene.handles.menu.transform.main,'Enable','on');
        set(thisScene.handles.menu.dynamic.main,'Enable','on');
        set(thisScene.handles.menu.addons.main,'Enable','on');
        try
            delete(thisScene.handles.electrodeImage1);
            for i=1:4
                delete(thisScene.handles.barLeft.num2str(i));
                delete(thisScene.handles.barTextLeft.num2str(i));
            end
        catch
        end
        try
            delete(thisScene.handles.electrodeImage2);
            for i=1:4
                delete(thisScene.handles.barRight.num2str(i));
                delete(thisScene.handles.barTextRight.num2str(i));
            end
        catch
        end
        set(thisScene.handles.figure,'CurrentAxes',thisScene.handles.axes);
        campos(thisScene.handles.axes,[ypos(1,1) ypos(1,2) ypos(1,3) ]);
        notify(thisScene.handles.menu.dynamic.Electrode.results,'Action');
    end

    function menu_closePredictionWindow(hObject,eventdata)
        thisScene=ArenaScene.getscenedata(hObject);
        thisScene.handles.menu.dynamic.Electrode.close.Enable='off';
        thisScene.handles.text_box_listSelectResult.Visible='off';
        thisScene.handles.box_listSelectResult.Visible='off';
        thisScene.handles.confirmbutton_box_listSelectResult.Visible='off';
        thisScene.handles.closebutton_box_listSelectResult.Visible='off';
        
    end

    function menu_showOldResults(hObject,eventdata)
        waitfor(msgbox('Please select your old Results from other Prediction!'));
        [file,pathDirectory]=uigetfile('*.xls','Select old Results');
        c=load('predictionConfig.mat');   %for every .xls data there is a appropriate .mat file which is used for the displaying of old results
        file=[file(1:end-4),'.mat'];
        result=load([c.predictionConfig.Temp,'/',file]);
        d=predictResults();
        d.displayHighestResults(result);
    end

        function Scene = getpredictdata(h)
            while not(isa(h.UserData,'ArenaScene'))
                h = h.Parent;
            end
            Scene = h.UserData;
        end

disp('ISS docking completed for prediction toolbox!');

end


classdef predictFuture<handle
    %This class is the replacement of the old Predict.m file
    %   It is in construction...
    
    % If you want to jump to specific part in the hirarchy of the functions
    % please use:
    % MAC: Cmd + f
    % Windows: Windows key + f
    % Search possebilities:
    % primary functions
    %   newPrediction
    %   closePrediction
    %   kSnapshotPrediction
    %   buttonStartSubprogramm
    % secondary functions
    %   menuImportfile
    %   buttonStartPrediction
    %   menuSavePrediction
    
    properties
        Title
        Patient_Information
        handles
        SavePath
        VTAPoolPath
        Tag
        config
        configStructure
        Data_In
        confidenceLevel
        Results
    end
    
    properties (Hidden)
        Temp
        Data_Out
        PositionHemisphere
        bilateralOn=0
        Heatmap
        amplitudesParameter=[6,1,8] %an option needs to be designed, to set those values like the user wants to
        proOptions=0
    end
    
    methods
        %------
        % all primary functions are inside here
        
        function obj = predictFuture()
            %First linking of class to variable
        end
        
        function  newPrediction(obj,pathDirectory)
            %It builds the enviroment to work on predictions
            
            % Everything which runs before the window is opened, comes
            % here...
            
            obj.handles=[];
            
            xpos=0.15;
            ypos=0.1;
            xwidth=0.7;
            yheight=0.7;
            
            obj.handles.figure=figure('units','normalized',...
                'outerposition',[xpos ypos xwidth yheight],...
                'menubar','none',...
                'name','Prediction Enviroment',...
                'numbertitle','off',...
                'resize','off',...
                'UserData',obj,...
                'CloseRequestFcn',@closePrediction,...
                'WindowKeyPressFcn',@kSnapshotPrediction,...
                'Color',[1 1 1]);
            
            obj.handles.heatmapText=uicontrol('parent',obj.handles.figure,...
                'units','normalized',...
                'outerposition',[0.57 0.6 0.4 0.05],...
                'String','Please select a heatmap!',...
                'style','text');
            
            obj.handles.heatmapListbox=uicontrol('parent',obj.handles.figure,...
                'units','normalized',...
                'style','listbox',...
                'outerposition',[0.57 0.45 0.4 0.1],...
                'String',{'DystoniaWürzburg(gpi)','BostonBerlin(stn)','BostonAlone(stn)'},...
                'BackgroundColor',[0.5 0.5 0.5],...
                'Tooltip',{['This heatmap was designed as part of a study made by Dr. Reich and Mr. Roothans in May 2019',newline,...
                ' with the name "Probabilistic mapping of the antidystonic effect of pallidal neurostimulation"']},...
                'Value',1,...
                'FontName','Arial',...
                'FontSize',14,...
                'Callback',{@heatmapListbox});
            
            [pic,map]=imread('glass_sphere.png');
            
            pic=imresize(pic,0.148);
            
            obj.handles.runButton=uicontrol('parent',obj.handles.figure,...
                'units','normalized',...
                'outerposition',[0.68 0.1 0.173 0.3],...
                'String','Run Prediction',...
                'BackgroundColor',[0.5 0.5 0.5],...
                'FontName','Arial',...
                'FontSize',14,...
                'cdata',pic,...
                'Callback',{@runButton});
            
            obj.handles.menu.file.main=uimenu('parent',obj.handles.figure,...
                'Text','File',...
                'ForegroundColor','black',...
                'Visible','off');
            
            obj.handles.menu.file.Sound.main=uimenu('parent',obj.handles.menu.file.main,...
                'Accelerator','A',...
                'Text','Finish Sound  (Com+A)','callback',{@SoundOn});
            
            obj.handles.menu.file.heatmap.main=uimenu('parent',obj.handles.menu.file.main,...
                'Text','Heatmap');
            %submenu for the heatmap setting
            obj.handles.menu.file.heatmapDystoniaWuerzburgMartin.main=uimenu('parent',obj.handles.menu.file.heatmap.main,...
                'Text','Dystonia Würzburg','callback',{@dystoniaWuerzburgMartin});
            obj.handles.menu.file.heatmapBostonBerlin.main=uimenu('parent',obj.handles.menu.file.heatmap.main,...
                'Text','BostonBerlin','callback',{@heatmapBostonBerlin});
            obj.handles.menu.file.heatmapBostonAlone.main=uimenu('parent',obj.handles.menu.file.heatmap.main,...
                'Text','BostonAlone','callback',{@heatmapBostonAlone});
            
            obj.handles.menu.file.changeVTAPoolPath.main=uimenu('parent',obj.handles.menu.file.main,...
                'Text','Change VTA Pool','callback',{@changeVTAPoolPath});
            obj.handles.menu.file.SaveDirectory.main=uimenu('parent',obj.handles.menu.file.main,...
                'Accelerator','S',...
                'Text','Change Save Directory (Com+S)','callback',{@saveFolder});
            
            obj.handles.menu.file.BilateralOn.main=uimenu('parent',obj.handles.menu.file.main,...
                'Text','Bilateral Prediction ','callback',{@BilateralOn});
            
            % the try and catch is added, because this way the prediction
            % for a single vta is made possible-> has it's own class
            
            if pathDirectory>0
                obj.handles.importButton.Visible='off';
                obj.Data_In=pathDirectory;
            end
            
            if pathDirectory==0
                obj.handles.menu.file.import.main=uimenu('parent',obj.handles.menu.file.main,...
                    'Accelerator','I',....
                    'Text','Import File(Com+I)','callback',@Import);
                
                obj.handles.importButton=uicontrol('parent',obj.handles.figure,...
                    'units','normalized',...
                    'outerposition',[0.02 0.15 0.5 0.6],...
                    'String','Import File',...
                    'BackgroundColor',[0.5 0.5 0.5],...
                    'FontName','Arial',...
                    'FontSize',14,...
                    'Visible','off',...
                    'Callback',@Import);
            end
            
            %%------
            %everything which is executed after the enviroment is built
            
            obj.handles.SoundOn=struct('value',0,'gong',0);
            obj.handles.SoundOn.value=0;
            obj.handles.menu.file.main.Visible='on';
            if obj.Data_In>0
                obj.handles.menu.file.import.main.ForegroundColor=[0 0.4470 0.7410];
                obj.Data_Out.Creation_Date=now;
                obj.handles.heatmapText.OuterPosition=[0.3 0.6 0.4 0.05];
                obj.handles.heatmapListbox.OuterPosition=[0.3 0.45 0.4 0.1];
                obj.handles.runButton.OuterPosition=[0.41 0.1 0.173 0.3];
            else
                obj.handles.importButton.Visible='on';
            end
            
        
        
        
        
        %% -----
        %Essential function for rudiment working
        function closePrediction(hObject,eventdata)
            request=questdlg('Are you sure you want to close the Prediction?','Confirmation',...
                'Cancel','Yes','Yes');
            switch request
                case 'Cancel'
                    return
                case 'Yes'
                    delete(gcf);
            end
        end
        
        function kSnapshotPrediction (hObject,eventdata)
            spaceBarPressed=eventdata.Key;
            if strcmpi(spaceBarPressed,'space')
                h=getframe(gcf);
                text=inputdlg('Type your number of the screenshot: ');
                name='.png';
                text=char(text);
                imwrite(h.cdata,['screenshot',text,name]);
            end
        end
        
        function saveFolder(hObject,eventdata)
            thisprediction=predictFuture.getpredictdata(hObject);
            %definition of the save path
            thisprediction.SavePath=uigetdir('/Users','Save to');
            if not(any(thisprediction.SavePath))
                return
            end
            try
                load('predictionConfig.mat');
            catch
                error('This function can only be used if the prediction add on was already onetime executed');
            end
            predictionConfig.SavePath=thisprediction.SavePath;
            folder=what('Prediction');
            save(fullfile(folder.path,'/predictionConfig'),'predictionConfig');
        end
        
        function Import(hObject,eventdata)
            thisprediction=predictFuture.getpredictdata(hObject);
            [filename,pathname]=uigetfile('*.dcm');
            if not(any(filename))
                warning('You did not select a file!');
                return
            end
            thisprediction.handles.menu.file.import.main.ForegroundColor=[0 0.4470 0.7410];
            thisprediction.Data_In=fullfile(pathname,filename);
            thisprediction.Data_Out.Creation_Date=now;
            thisprediction.handles.target='gpi';
            thisprediction.handles.importButton.Visible='off';
        end
        
        function heatmapListbox(hObject,eventdata)
            thisprediction=predictFuture.getpredictdata(hObject);
            switch thisprediction.handles.heatmapListbox.Value
                case 1
                    thisprediction.handles.menu.file.heatmapDystoniaWuerzburgMartin.main.MenuSelectedFcn(hObject,eventdata);
                    thisprediction.handles.heatmapListbox.Tooltip={['This heatmap was designed as part of a study made by Dr. Reich and Mr. Roothans in May 2019',newline,...
                        ' with the name "Probabilistic mapping of the antidystonic effect of pallidal neurostimulation"']};
                case 2
                    thisprediction.handles.menu.file.heatmapBostonBerlin.main.MenuSelectedFcn(hObject,eventdata);
                    thisprediction.handles.heatmapListbox.Tooltip={'This heatmap was designed as part of a cooperation between Boston and Berlin and is still in progress!'};
                case 3
                    thisprediction.handles.menu.file.heatmapBostonAlone.main.MenuSelectedFcn(hObject,eventdata);
                    thisprediction.handles.heatmapListbox.Tooltip={'This heatmap was designed by a team of researches from Boston and is still in progress!'};
                    
                    
            end
        end
        %% -----
        %all secondary functions are inside here
        function runButton(hObject,eventdata)
            thisprediction=predictFuture.getpredictdata(hObject);
            
            if thisprediction.handles.heatmapListbox.Value==1
                dystoniaWuerzburgMartin(hObject,eventdata);
            end
            
            thisprediction.handles.runButton.Enable='inactive';
            
            if isempty(thisprediction.Data_In)
                error('You did not provide the programm with the right data!');
            end
            
            if ~(strcmp(thisprediction.Data_In(end-3:end),'.dcm'))
                warning('You selected the wrong filetype as input!!!');
                return
            end
            
            b=buttonConnected();
            waitbarFigurePredictFuture=uifigure;
            b.progress=uiprogressdlg(waitbarFigurePredictFuture,'Message','VTAs will be prepared!','Value',0.1,'ShowPercentage','on');
            pause(3);
            [thisprediction.handles.VTA_Information,thisprediction.Patient_Information,result] =b.VTA_Transformation(thisprediction);
            if result==0
                b.progress.Message='Prediction is in progress!';
                b.progress.Value=0.3;
                pause(1);
                [thisprediction.handles.prediction_Information.bilateral,thisprediction.handles.prediction_Information.unilateral]=b.predictionProcess(thisprediction);
                b.progress.Message='Prediction is finished!';
                b.progress.Value=0.8;
                b.saveTheData(thisprediction);
                b.progress.Message='Data is stored';
                if thisprediction.proOptions==1
                    b.progress.Value=0.9;
                    b.showTheData(thisprediction);
                end
                b.progress.Value=1;
                b.progress.Message='Finished';
                pause(3);
                if thisprediction.handles.SoundOn.value
                    % if you are not around looking on the monitor, then you
                    % can just hear it is finished
                    thisprediction.handles.SoundOn.gong=load('gong.mat');
                    gong = audioplayer(thisprediction.handles.SoundOn.gong.y, thisprediction.handles.SoundOn.gong.Fs);
                    play(gong);
                    pause(3);
                end
                delete(waitbarFigurePredictFuture);
            else
                thisprediction.Heatmap.Name=0;
                delete(waitbarFigurePredictFuture);
            end
            delete(findobj('Name','Prediction Enviroment'));
            waitfor(msgbox('Your Prediction is done!'));
        end
        
        function SoundOn(hObject,eventdata)
            thisprediction=predictFuture.getpredictdata(hObject);
            if thisprediction.handles.SoundOn.value==1
                thisprediction.handles.SoundOn.value=0;
                thisprediction.handles.menu.file.Sound.main.ForegroundColor='black';
            else
                thisprediction.handles.SoundOn.value=1;
                thisprediction.handles.menu.file.Sound.main.ForegroundColor=[0 0.4470 0.7410];
            end
        end
        
        function BilateralOn(hObject,eventdata)
            thisprediction=predictFuture.getpredictdata(hObject);
            if thisprediction.bilateralOn==1
                thisprediction.bilateralOn=0;
                thisprediction.handles.menu.file.BilateralOn.main.ForegroundColor='black';
            else
                thisprediction.bilateralOn=1;
                thisprediction.handles.menu.file.BilateralOn.main.ForegroundColor=[0 0.4470 0.7410];
            end
        end
        function dystoniaWuerzburgMartin(hObject,eventdata)
            thisprediction=predictFuture.getpredictdata(hObject);
            thisprediction.Heatmap.Name='DystoniaWuerzburg';
            if not(isa(thisprediction.Data_In,'Mesh'))
                if thisprediction.handles.menu.file.heatmapDystoniaWuerzburgMartin.main.ForegroundColor(1,3)==0
                    thisprediction.handles.menu.file.heatmapDystoniaWuerzburgMartin.main.ForegroundColor=[0 0.4470 0.7410];
                    thisprediction.handles.menu.file.heatmapBostonBerlin.main.ForegroundColor='black';
                    thisprediction.handles.menu.file.heatmapBostonAlone.main.ForegroundColor='black';
                    thisprediction.handles.target='gpi';
                else
                    thisprediction.handles.menu.file.heatmapDystoniaWuerzburgMartin.main.ForegroundColor='black';
                    thisprediction.handles.target='';
                    thisprediction.Heatmap.Name='';
                end
            else
            end
            
        end
        
        function heatmapBostonBerlin(hObject,eventdata)
            thisprediction=predictFuture.getpredictdata(hObject);
            thisprediction.Heatmap.Name='heatmapBostonBerlin';
            if not(isa(thisprediction.Data_In,'Mesh'))
                if thisprediction.handles.menu.file.heatmapBostonBerlin.main.ForegroundColor(1,3)==0
                    thisprediction.handles.menu.file.heatmapBostonBerlin.main.ForegroundColor=[0 0.4470 0.7410];
                    thisprediction.handles.menu.file.heatmapDystoniaWuerzburgMartin.main.ForegroundColor='black';
                    thisprediction.handles.menu.file.heatmapBostonAlone.main.ForegroundColor='black';
                    thisprediction.handles.target='stn';
                else
                    thisprediction.handles.menu.file.heatmapBostonBerlin.main.ForegroundColor='black';
                    thisprediction.Heatmap.Name='';
                    thisprediction.handles.target='';
                end
            else
            end
        end
        
        function heatmapBostonAlone(hObject,eventdata)
            thisprediction=predictFuture.getpredictdata(hObject);
            thisprediction.Heatmap.Name='heatmapBostonAlone';
            if not(isa(thisprediction.Data_In,'Mesh'))
                if thisprediction.handles.menu.file.heatmapBostonAlone.main.ForegroundColor(1,3)==0
                    thisprediction.handles.menu.file.heatmapBostonAlone.main.ForegroundColor=[0 0.4470 0.7410];
                    thisprediction.handles.menu.file.heatmapBostonBerlin.main.ForegroundColor='black';
                    thisprediction.handles.menu.file.heatmapDystoniaWuerzburgMartin.main.ForegroundColor='black';
                    thisprediction.handles.target='stn';
                else
                    thisprediction.handles.menu.file.heatmapBostonAlone.main.ForegroundColor='black';
                    thisprediction.Heatmap.Name='';
                    thisprediction.handles.target='';
                end
            else
            end
        end
        function changeVTAPoolPath(hObject,eventdata)
            waitfor(msgbox('You want to change searching path of your VTA Pool? Please choose...'));
            thisprediction.VTAPoolPath=uigetdir;
            load('predictionConfig.mat');
            predictionConfig.VTAPoolPath=thisprediction.VTAPoolPath;
            folder=what('Prediction');
            save(fullfile(folder.path,'/predictionConfig'),'predictionConfig');
        end
        end
    end
    
    %% This methode is used to get back at the first position in the hirarchy
    %of subclasses(parent, child):
    methods(Static)
        function thisprediction = getpredictdata(h)
            while not(isa(h.UserData,'predictFuture'))
                h = h.Parent;
            end
            thisprediction = h.UserData;
        end
    end
end


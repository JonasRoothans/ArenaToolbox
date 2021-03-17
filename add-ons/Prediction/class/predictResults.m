classdef predictResults<handle
    %This class is used for displaying diganosed results of predictions. It
    %can give the unilateral and bilateral top choosen results in combination
    %or without.
    
    properties
        handles
        HighestResults
        treshholdTwoStandard
        treshholdOneStandard
        usableAmplitudeMinusOneStd
        usableAmplitudePlusOneStd
    end
    
    methods
        function obj = predictResults()
            %this needs to be here
        end
        
        function displayHighestResults(varargin)
            
            if numel(varargin)==2
                obj=varargin{1};
                Actor=varargin{2};
            elseif numel(varargin)==3
                obj=varargin{1};
                thisScene=varargin{2};
                displayDecision=varargin{3};
                Actor=thisScene.Actors(1,displayDecision);
            end
            
            try
                if isa(Actor.PredictionAndVTA.prediction_Information,'struct')
                    A=Actor;
                    clear Actor
                    Actor.Name=A.Name;
                    Actor.PredictInformation.Results{1}=A.PredictionAndVTA.prediction_Information;
                    Actor.PredictInformation.configStructure=A.PredictionAndVTA.configStructure;
                    Actor.Tag=A.PredictionAndVTA.Tag;
                    Actor.PredictInformation.confidenceLevel=A.PredictionAndVTA.confidenceLevel;
                end
            catch
                if isa(Actor.PredictInformation.Results,'predictFuture')
                    return;
                end
            end
            
            
            obj.HighestResults=[];
            obj.HighestResults.bilateral=[];
            obj.HighestResults.unilateralLeft=[];
            obj.HighestResults.unilateralRight=[];
            obj.HighestResults.bilateral.position={};
            obj.HighestResults.unilateralLeft.position={};
            obj.HighestResults.unilateralRight.position={};
            dimensionsOfPredictionResults=Actor.PredictInformation.configStructure.numberOfContacts*Actor.PredictInformation.configStructure.numberOfContactSettings;
            contacts_vector=Actor.PredictInformation.configStructure.contacts_vector;
            amplitudes_vector=Actor.PredictInformation.configStructure.amplitudes_vector;
            
            img = imread('closeUpElectrode.png');
            img=imresize(img,0.5);
            thisScene.handles.barLeft=[];
            thisScene.handles.barRight=[];
            thisScene.handles.barTextLeft=[];
            thisScene.handles.barTextRight=[];
            loadedThresholds=load('memoryFile_AmplitudeSetting_ConfidenceThreshold_TrialDystoniaWürzburg.mat');
            obj.treshholdTwoStandard=loadedThresholds.averageToSave.twoStanardDeviationMinus;
            obj.treshholdOneStandard=loadedThresholds.averageToSave.oneStanardDeviationMinus;
            obj.usableAmplitudeMinusOneStd=loadedThresholds.averageToSave.usableAmplitudeMinusOneStd;
            obj.usableAmplitudePlusOneStd=loadedThresholds.averageToSave.usableAmplitudePlusOneStd;
            try
                oldPosition=thisScene.handles.axes.Position;
                set(thisScene.handles.axes,'Position',[0.01 0.01 0.2 0.2])
                figure1=thisScene.handles.figure;
            catch
                figure1=figure('Units','normalized','Position',[0.01 0.01 0.99 0.99],'Name',Actor.Name);
                uicontrol('parent',figure1,...
                    'units','normalized',...
                    'position',[0.8,0.1,0.2,0.05],...
                    'FontSize',12,...
                    'ForegroundColor','r',...
                    'String','All red written is outside of one standard deviation! ');
            end
            
            if not(isempty(Actor.PredictInformation.Results{1, 1}.unilateral.left))
                subplot(1,7,5)
                set(gca,'Position',[0.17 0.1 0.2 0.7]);
                thisScene.handles.electrodeImage1=imshow(img);
                if not(isempty(Actor.PredictInformation.confidenceLevel))
                    greaterThanThresholdLeftTwoStd=Actor.PredictInformation.confidenceLevel.leftSide.average>obj.treshholdTwoStandard;
                    greaterThanThresholdLeftTwoStd=Actor.PredictInformation.Results{1,1}.unilateral.left.*greaterThanThresholdLeftTwoStd;
                else
                    greaterThanThresholdLeftTwoStd=Actor.PredictInformation.Results{1,1}.unilateral.left;
                end
            end
            if not(isempty(Actor.PredictInformation.Results{1, 1}.unilateral.right))
                subplot(1,7,7)
                set(gca,'Position',[0.5 0.1 0.2 0.7]);
                thisScene.handles.electrodeImage2=imshow(img);
                if not(isempty(Actor.PredictInformation.confidenceLevel))
                    greaterThanThresholdRightTwoStd=Actor.PredictInformation.confidenceLevel.rightSide.average>obj.treshholdTwoStandard;
                    greaterThanThresholdRightTwoStd=Actor.PredictInformation.Results{1,1}.unilateral.right.*greaterThanThresholdRightTwoStd;
                else
                    greaterThanThresholdRightTwoStd=Actor.PredictInformation.Results{1,1}.unilateral.right;
                end
            end
            try
                set(thisScene.handles.axes,'Position',oldPosition);
            catch
            end
            
            for i=1:Actor.PredictInformation.configStructure.numberOfContacts
                %get the highest prediction result per contact
                ypos=0.19+(i-1)*0.109;
                obj.handles.xlength=[];
                try
                    if  not(isempty(Actor.PredictInformation.Results{1, 1}.unilateral.left))
                        greaterThanThreshold=greaterThanThresholdLeftTwoStd;
                        bar='barLeft';
                        barText='barTextLeft';
                        position=[0.3 ypos 0 0.08];
                        positionAmplitude=[0.3 ypos 0.04 0.08];
                        side='leftSide';
                        creationOfObejcts(thisScene,Actor,greaterThanThreshold,bar,barText,...
                            position,positionAmplitude,side,i,Actor.PredictInformation.confidenceLevel.leftSide.average);
                    end
               catch
                end
                    if not(isempty(Actor.PredictInformation.Results{1, 1}.unilateral.right))
                        greaterThanThreshold=greaterThanThresholdRightTwoStd;
                        bar='barRight';
                        barText='barTextRight';
                        position=[0.63 ypos 0 0.08];
                        positionAmplitude=[0.63 ypos 0.04 0.08];
                        side='rightSide';
                        creationOfObejcts(thisScene,Actor,greaterThanThreshold,bar,barText,...
                            position,positionAmplitude,side,i,Actor.PredictInformation.confidenceLevel.rightSide.average);
                    end
            end
            
            function creationOfObejcts(thisScene,Actor,greaterThanThreshold,bar,barText,position,positionAmplitude,side,i,confidenceLevel)
                numberOfContactsSettings=Actor.PredictInformation.configStructure.numberOfContactSettings;
                maxForContact=maxk(greaterThanThreshold(1+numberOfContactsSettings*(i-1):numberOfContactsSettings*i),1);
                positionOfNumberInVector=find(greaterThanThreshold(1+numberOfContactsSettings*(i-1):numberOfContactsSettings*i)==maxForContact)+numberOfContactsSettings*(i-1);
                maxForContact=unique(maxForContact);
                maxForContact=round(maxForContact,2);
                if maxForContact==0
                    valueOfStimulation=[];
                else
                    valueOfStimulation=amplitudes_vector(1,positionOfNumberInVector(1,1));
                end
                if maxForContact<1 && maxForContact>0
                    obj.handles.xlength=0.02+maxForContact/8;
                elseif maxForContact>1
                    obj.handles.xlength=0.02+maxForContact/800;
                else
                    obj.handles.xlength=0;
                    valueOfStimulation=[];
                    disp(['An only negative or lower than the threshold prediction was done for ',bar,' ',num2str(i-1)])
                end
                position(1,3)=position(1,3)+obj.handles.xlength;
                if not(isempty(valueOfStimulation))
                    thisScene.handles.(bar).num2str(i)=uicontrol('parent',figure1,...
                        'Style','text',...
                        'BackgroundColor',[0, 0.4470, 0.7410],...
                        'Units','normalized',...
                        'Position',position,...
                        'FontWeight','bold',...
                        'FontAngle','italic',...
                        'FontSize',18,...
                        'String',[newline,num2str(maxForContact)]);
                    positionAmplitude(1,1)=positionAmplitude(1,1)+obj.handles.xlength;
                    thisScene.handles.(barText).num2str(i)=uicontrol('parent',figure1,...
                        'Style','text',...
                        'BackgroundColor',[0.4660, 0.6740, 0.1880],...
                        'Units','normalized',...
                        'Position',positionAmplitude,...
                        'FontWeight','bold',...
                        'FontAngle','italic',...
                        'FontSize',18,...
                        'String',[newline,num2str(valueOfStimulation),'mA']);
                    positionAmplitude(1,1)=positionAmplitude(1,1)+obj.handles.xlength/2;
                    thisScene.handles.([(barText),'confidence']).num2str(i)=uicontrol('parent',figure1,...
                        'Style','text',...
                        'BackgroundColor',[1 1 1],...
                        'Units','normalized',...
                        'Position',positionAmplitude,...
                        'FontWeight','bold',...
                        'FontAngle','italic',...
                        'FontSize',12,...
                        'String',[newline,num2str(round(confidenceLevel(positionOfNumberInVector(1,1)),4)),'AU']);
                    if Actor.PredictInformation.confidenceLevel.(side).average(positionOfNumberInVector(1,1))<obj.treshholdOneStandard
                        thisScene.handles.(bar).num2str(i).ForegroundColor='r';
                    end
                    try
                        if valueOfStimulation<obj.usableAmplitudeMinusOneStd || valueOfStimulation>obj.usableAmplitudePlusOneStd
                            thisScene.handles.(barText).num2str(i).ForegroundColor='r';
                        end
                    catch
                    end
                    
                else
                    thisScene.handles.(barText).num2str(i)=uicontrol('Visible','off');
                    thisScene.handles.(bar).num2str(i)=uicontrol('Visible','off');
                end
            end
            end

    function kSnapshotResult (hObject,eventdata)
    spaceBarPressed=eventdata.Key;
    if strcmpi(spaceBarPressed,'space')
        h=getframe(gcf);
        text=inputdlg('Type your number of the screenshot: ');
        name='.png';
        text=char(text);
        imwrite(h.cdata,['screenshot',text,name]);
    end
    end
    
    end
end

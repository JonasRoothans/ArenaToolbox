classdef predictResults<handle
    %This class is used for displaying diganosed results of predictions. It
    %can give the unilateral and bilateral top choosen results in combination
    %or without.
    
    properties
        handles
        HighestResults
        devoloperOptions2=0
        treshhold
        topScoreValue=3
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
            
            
            obj.topScoreValue=3; % If in in the future this an other value is needed, you can add the outcomings here.
            
            try
                if isa(Actor.PredictionAndVTA.prediction_Information,'struct')
                    A=Actor;
                    clear Actor
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
   
            if obj.devoloperOptions2==1
                
                %                 %first bilateral
                
                obj.handles.figure=figure('Units','normalized',...
                    'Position',[0.05 0 0.9 0.9],...
                    'Name','Results',...
                    'WindowKeyPressFcn',@kSnapshotResult);
                
                if not(isempty(Actor.PredictInformation.Results{1}.bilateral))
                    greaterThanThresholdBilateral=Actor.PredictInformation.confidenceLevel.bilateral.average>obj.treshhold*2;
                    greaterThanThresholdBilateral=Actor.PredictInformation.Results{1,1}.bilateral.*greaterThanThresholdBilateral;
                    obj.HighestResults.bilateral.results=unique(greaterThanThresholdBilateral);
                    obj.handles.bilateralText=uicontrol('Parent',obj.handles.figure,'Style','text','String','Bilateral results',...
                        'Units','normalized','Position',[0.35 0.8 0.1 0.05],'BackgroundColor',[0 0.4470 0.7410]);
                    ypos=0;
                    for i=1:obj.topScoreValue
                        ypos=0.9-i*0.25;
                        obj.handles.panelsForBilateral(1,i)=uicontrol('Parent',obj.handles.figure,'Style','text',...
                            'Units','normalized','Position',[0.35 ypos 0.1 0.1],'BackgroundColor',[0.3010, 0.7450, 0.9330]);
                    end
                    
                    obj.HighestResults.bilateral.results=maxk(Actor.PredictInformation.Results{1,1}.bilateral,obj.topScoreValue);
                    obj.HighestResults.bilateral.results=reshape(obj.HighestResults.bilateral.results,[1,(obj.topScoreValue*dimensionsOfPredictionResults)]);
                    obj.HighestResults.bilateral.results=unique(obj.HighestResults.bilateral.results);
                    obj.HighestResults.bilateral.results=maxk(obj.HighestResults.bilateral.results,obj.topScoreValue);
                    
                    for itopScoreValue=1:obj.topScoreValue
                        obj.HighestResults.bilateral.position{itopScoreValue}=ismember(Actor.PredictInformation.Results{1,1}.bilateral,obj.HighestResults.bilateral.results(1,itopScoreValue));
                        [row,col]=find(obj.HighestResults.bilateral.position{itopScoreValue});
                        part='C%s-%smA';
                        if not(numel(col)==0)
                            part1=sprintf(part,num2str(contacts_vector(1,row(1,1))),num2str(amplitudes_vector(1,row(1,1))));
                            part2=sprintf(part,num2str(contacts_vector(1,col(1,1))),num2str(amplitudes_vector(1,col(1,1))));
                            if numel(row)>1 || numel(col)>1
                                for i=2:numel(row)
                                    helpPart=sprintf(part,num2str(contacts_vector(1,row(i,1))),num2str(amplitudes_vector(1,row(i,1))));
                                    part1=[part1,' or ',newline,helpPart];
                                end
                                part1=[part1,'"l"'];
                                for i=2:numel(col)
                                    helpPart=sprintf(part,num2str(contacts_vector(1,col(i,1))),num2str(amplitudes_vector(1,col(i,1))));
                                    part2=[part2,' or ',newline,helpPart];
                                end
                                part2=[part2,'"r"'];
                            end
                            obj.handles.panelsForBilateral(1,itopScoreValue).String=sprintf([part1,' and ',newline,part2,newline,num2str(obj.HighestResults.bilateral.results(1,itopScoreValue))]);
                        end
                    end
                end
                
                %second left
                if not(isempty(Actor.PredictInformation.Results{1, 1}.unilateral.left))
                    greaterThanThreshold=Actor.PredictInformation.confidenceLevel.leftSide.average>obj.treshhold;
                    greaterThanThreshold=Actor.PredictInformation.Results{1,1}.unilateral.left.*greaterThanThreshold;
                    obj.HighestResults.unilateralLeft.results=unique(greaterThanThreshold);
                    obj.handles.bilateralText=uicontrol('Parent',obj.handles.figure,'Style','text','String','Unilateral left results',...
                        'Units','normalized','Position',[0.465 0.8 0.1 0.05],'BackgroundColor',[0 0.4470 0.7410]);
                    ypos=0;
                    
                    obj.handles.leftVTAPrediction=uicontrol('Parent',obj.handles.figure,'Style','text','String',['VTA connected to the lead left prediction',...
                        newline,num2str(Actor.PredictInformation.handles.prediction_Information.unilateral.leftVTAPrediction)],...
                        'Units','normalized','Position',[0.04 0.65 0.08 0.1],'BackgroundColor',[0.4660, 0.6740, 0.1880]);
                    
                    for i=1:obj.topScoreValue
                        ypos=0.9-i*0.25;
                        obj.handles.panelsForLeft(1,i)=uicontrol('Parent',obj.handles.figure,'Style','text',...
                            'Units','normalized','Position',[0.465 ypos 0.1 0.1],'BackgroundColor',[0.3010, 0.7450, 0.9330]);
                    end
                    obj.HighestResults.unilateralLeft.results=maxk(obj.HighestResults.unilateralLeft.results,obj.topScoreValue);
                    for itopScoreValue=1:obj.topScoreValue
                        obj.HighestResults.unilateralLeft.position{itopScoreValue}=ismember(Actor.PredictInformation.Results{1,1}.unilateral.left,obj.HighestResults.unilateralLeft.results(1,itopScoreValue));
                        [row,col]=find(obj.HighestResults.unilateralLeft.position{itopScoreValue});
                        row=unique(row);
                        col=unique(col);
                        part='C%s-%smA';
                        if not(numel(col)==0)
                            nameing=sprintf(part,num2str(contacts_vector(1,...
                                col(1,1))),num2str(amplitudes_vector(1,col(1,1))));
                            if numel(col)>1
                                for i=2:numel(col)
                                    nameing2=sprintf(part,num2str(contacts_vector(1,col(1,...
                                        i))),num2str(amplitudes_vector(1,col(1,i))));
                                    nameing=[nameing,' or ',newline, nameing2];
                                end
                            end
                            obj.handles.panelsForLeft(1,itopScoreValue).String=[nameing,...
                                newline,num2str(obj.HighestResults.unilateralLeft.results(1,itopScoreValue))];
                        end
                    end
                end
                
                %thrid right
                if not(isempty(Actor.PredictInformation.Results{1, 1}.unilateral.right))
                    greaterThanThreshold=Actor.PredictInformation.confidenceLevel.rightSide.average>obj.treshhold;
                    greaterThanThreshold=Actor.PredictInformation.Results{1,1}.unilateral.right.*greaterThanThreshold;
                    obj.HighestResults.unilateralRight.results=unique(greaterThanThreshold);
                    obj.handles.bilateralText=uicontrol('Parent',obj.handles.figure,'Style','text','String','Unilateral right results',...
                        'Units','normalized','Position',[0.58 0.8 0.1 0.05],'BackgroundColor',[0 0.4470 0.7410]);
                    ypos=0;
                    
                    obj.handles.rightVTAPrediction=uicontrol('Parent',obj.handles.figure,'Style','text','String',['VTA connected to the lead right prediction',...
                        newline,num2str(Actor.PredictInformation.handles.prediction_Information.unilateral.rightVTAPrediction)],...
                        'Units','normalized','Position',[0.14 0.65 0.08 0.1],'BackgroundColor',[0.4660, 0.6740, 0.1880]);
                    
                    for i=1:obj.topScoreValue
                        ypos=0.9-i*0.25;
                        obj.handles.panelsForRight(1,i)=uicontrol('Parent',obj.handles.figure,'Style','text',...
                            'Units','normalized','Position',[0.58 ypos 0.1 0.1],'BackgroundColor',[0.3010, 0.7450, 0.9330]);
                    end
                    obj.HighestResults.unilateralRight.results=maxk(obj.HighestResults.unilateralRight.results,obj.topScoreValue);
                    for itopScoreValue=1:obj.topScoreValue
                        obj.HighestResults.unilateralRight.position{itopScoreValue}=ismember(Actor.PredictInformation.Results{1,1}.unilateral.right,obj.HighestResults.unilateralRight.results(1,itopScoreValue));
                        [row,col]=find(obj.HighestResults.unilateralRight.position{itopScoreValue});
                        row=unique(row);
                        col=unique(col);
                        part='C%s-%smA';
                        if not(numel(col)==0)
                            nameing=sprintf(part,num2str(contacts_vector(1,...
                                col(1,1))),num2str(amplitudes_vector(1,col(1,1))));
                            if numel(col)>1
                                for i=2:numel(col)
                                    nameing2=sprintf(part,num2str(contacts_vector(1,col(1,...
                                        i))),num2str(amplitudes_vector(1,col(1,i))));
                                    nameing=[nameing,' or ',newline, nameing2];
                                end
                            end
                            obj.handles.panelsForRight(1,itopScoreValue).String=[nameing,...
                                newline,num2str(obj.HighestResults.unilateralRight.results(1,itopScoreValue))];
                        end
                    end
                end
            else
                img = imread('closeUpElectrode.png');
                thisScene.handles.barLeft=[];
                thisScene.handles.barRight=[];
                thisScene.handles.barTextLeft=[];
                thisScene.handles.barTextRight=[];
                load('memoryFileConfidenceLevelOfTrialDystoniaCases.mat');
                obj.treshhold=averageToSave.twoStanardDeviationMinus;
                
                if not(isempty(Actor.PredictInformation.Results{1, 1}.unilateral.left))
                    try
                        oldPosition=thisScene.handles.axes.Position;
                        set(thisScene.handles.axes,'Position',[0.01 0.01 0.2 0.2])
                        figure1=thisScene.handles.figure;
                    catch
                        figure1=figure;
                    end
                    subplot(1,7,5)
                    set(gca,'Position',[0.17 0.1 0.2 0.7]);
                    try
                        set(thisScene.handles.axes,'Position',oldPosition);
                    catch
                    end
                    img=imresize(img,0.5);
                    thisScene.handles.electrodeImage1=imshow(img);
                    if not(isempty(Actor.PredictInformation.confidenceLevel))
                        greaterThanThresholdLeft=Actor.PredictInformation.confidenceLevel.leftSide.average>obj.treshhold;
                        greaterThanThresholdLeft=Actor.PredictInformation.Results{1,1}.unilateral.left.*greaterThanThresholdLeft;
                    else
                        greaterThanThresholdLeft=Actor.PredictInformation.Results{1,1}.unilateral.left;
                    end
                end
                if not(isempty(Actor.PredictInformation.Results{1, 1}.unilateral.right))
                    try
                        oldPosition=thisScene.handles.axes.Position;
                        set(thisScene.handles.axes,'Position',[0.01 0.01 0.2 0.2])
                        figure1=thisScene.handles.figure;
                    catch
                        figure1=figure;
                    end
                    subplot(1,7,7)
                    set(gca,'Position',[0.5 0.1 0.2 0.7]);
                    try
                        set(thisScene.handles.axes,'Position',oldPosition);
                    catch
                    end
                    img=imresize(img,0.5);
                    thisScene.handles.electrodeImage2=imshow(img);
                    
                    if not(isempty(Actor.PredictInformation.confidenceLevel))
                        greaterThanThresholdRight=Actor.PredictInformation.confidenceLevel.rightSide.average>obj.treshhold;
                        greaterThanThresholdRight=Actor.PredictInformation.Results{1,1}.unilateral.right.*greaterThanThresholdRight;
                    else
                        greaterThanThresholdRight=Actor.PredictInformation.Results{1,1}.unilateral.right;
                    end
                end
                numberOfContactsSettings=Actor.PredictInformation.configStructure.numberOfContactSettings;
                for i=1:Actor.PredictInformation.configStructure.numberOfContacts
                    %get the highest prediction result per contact
                    ypos=0.19+(i-1)*0.109;
                    try
                        if  not(isempty(Actor.PredictInformation.Results{1, 1}.unilateral.left))
                            maxForContactLeft=maxk(greaterThanThresholdLeft(1+numberOfContactsSettings*(i-1):numberOfContactsSettings*i),1);
                            positionOfNumberInVector=find(greaterThanThresholdLeft(1+numberOfContactsSettings*(i-1):numberOfContactsSettings*i)==maxForContactLeft);
                            maxForContactLeft=unique(maxForContactLeft);
                            if maxForContactLeft==0
                                valueOfStimulationLeft=[];
                            else
                                valueOfStimulationLeft=amplitudes_vector(1,positionOfNumberInVector(1,1));
                            end
                            if maxForContactLeft<1 && maxForContactLeft>0
                                xlengthLeft=0.02+maxForContactLeft/8;
                            elseif maxForContactLeft>1
                                xlengthLeft=0.02+maxForContactLeft/800;
                            else
                                xlengthLeft=0;
                                valueOfStimulationLeft=[];
                                disp(['An only negative or lower than the threshold prediction was done for left contact',num2str(i-1)])
                            end
                            positionLeft=[0.3 ypos xlengthLeft 0.08];
                            if not(isempty(valueOfStimulationLeft))
                                thisScene.handles.barLeft.num2str(i)=uicontrol('parent',figure1,...
                                    'Style','text',...
                                    'BackgroundColor',[0, 0.4470, 0.7410],...
                                    'Units','normalized',...
                                    'Position',positionLeft,...
                                    'FontWeight','bold',...
                                    'FontAngle','italic',...
                                    'FontSize',18,...
                                    'String',[newline,num2str(maxForContactLeft)]);
                                positionLeft=[0.3+xlengthLeft ypos 0.04 0.08];
                                thisScene.handles.barTextLeft.num2str(i)=uicontrol('parent',figure1,...
                                    'Style','text',...
                                    'BackgroundColor',[0.4660, 0.6740, 0.1880],...
                                    'Units','normalized',...
                                    'Position',positionLeft,...
                                    'FontWeight','bold',...
                                    'FontAngle','italic',...
                                    'FontSize',18,...
                                    'String',[newline,num2str(valueOfStimulationLeft),'mA']);
                            else
                                thisScene.handles.barTextLeft.num2str(i)=uicontrol('Visible','off');
                                thisScene.handles.barLeft.num2str(i)=uicontrol('Visible','off');
                            end
                        end
                    catch
                    end
                    
                    if not(isempty(Actor.PredictInformation.Results{1, 1}.unilateral.right))
                        maxForContactRight=maxk(greaterThanThresholdRight(1+numberOfContactsSettings*(i-1):numberOfContactsSettings*i),1);
                        positionOfNumberInVector=find(greaterThanThresholdRight(1+numberOfContactsSettings*(i-1):numberOfContactsSettings*i)==maxForContactRight);
                        maxForContactRight=unique(maxForContactRight);
                        if maxForContactRight==0
                            valueOfStimulationRight=[];
                        else
                            valueOfStimulationRight=amplitudes_vector(1,positionOfNumberInVector(1,1));
                        end
                        if maxForContactRight<1 && maxForContactRight>0
                            xlengthRight=0.02+maxForContactRight/8;
                        elseif maxForContactRight>1
                            xlengthRight=0.02+maxForContactRight/800;
                        else
                            xlengthRight=0;
                            valueOfStimulationRight=[];
                            disp(['An only negative or lower than the threshold prediction was done for right contact',num2str(i-1)])
                        end
                        positionRight=[0.63 ypos xlengthRight 0.08];
                        %construct the reference bar
                        if not(isempty(valueOfStimulationRight))
                            thisScene.handles.barRight.num2str(i)=uicontrol('parent',figure1,...
                                'Style','text',...
                                'BackgroundColor',[0, 0.4470, 0.7410],...
                                'Units','normalized',...
                                'Position',positionRight,...
                                'FontWeight','bold',...
                                'FontAngle','italic',...
                                'FontSize',18,...
                                'String',[newline,num2str(maxForContactRight)]);
                            positionRight=[0.63+xlengthRight ypos 0.04 0.08];
                            thisScene.handles.barTextRight.num2str(i)=uicontrol('parent',figure1,...
                                'Style','text',...
                                'BackgroundColor',[0.4660, 0.6740, 0.1880],...
                                'Units','normalized',...
                                'Position',positionRight,...
                                'FontWeight','bold',...
                                'FontAngle','italic',...
                                'FontSize',18,...
                                'String',[newline,num2str(valueOfStimulationRight),'mA']);
                        else
                            thisScene.handles.barRight.num2str(i)=uicontrol('Visible','off');
                            thisScene.handles.barTextRight.num2str(i)=uicontrol('Visible','off');
                        end
                    end
                    
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


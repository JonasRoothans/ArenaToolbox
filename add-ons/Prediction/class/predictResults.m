classdef predictResults<handle
    %This class is used for displaying diganosed results of predictions. It
    %can give the unilateral and bilateral top choosen results in combination
    %or without.
    
    properties
        handles
        HighestResults
        developerOptions1=0
        devoloperOptions2=0
        treshhold=7;
        topScoreValue=3
    end
    
    methods
        function obj = predictResults()
            %this needs to be here
        end
        
        function displayHighestResults(obj,thisScene,displayDecision)
            
            Actor=thisScene.Actors(1,displayDecision);
            
            obj.topScoreValue=3; % If in in the future this an other value is needed, you can add the outcomings here.
            
            try
                 if isa(Actor.PredictionAndVTA.prediction_Information,'struct')
                    A=Actor;
                    clear Actor
                    Actor.PredictInformation.Results{1}=A.PredictionAndVTA.prediction_Information;
                    Actor.PredictInformation.configStructure=A.PredictionAndVTA.configStructure;
                    Actor.Tag=A.PredictionAndVTA.Tag;
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
            
            if obj.developerOptions1==1
                
                obj.handles.figure=figure('Units','normalized',...
                'Position',[0.05 0 0.9 0.9],...
                'Name','Results',...
                'WindowKeyPressFcn',@kSnapshotResult);
            
                obj.handles.table_bilateral=uitable('Parent',obj.handles.figure,'Units','normalized',...
                    'OuterPosition',[0.05 0.64 0.9 0.3],...
                    'ColumnEditable',[false false],...
                    'ColumnName','Bilateral',...
                    'RowName',{},...
                    'BackgroundColor',[0.9290 0.6940 0.1250],...
                    'ForegroundColor','blue');
                
                
                obj.handles.table_unilateralLeft=uitable('Parent',fig1,'Units','normalized',...
                    'OuterPosition',[0.25 0.32 0.5 0.3],...
                    'ColumnEditable',[false false],...
                    'ColumnName','Unilateral Left',...
                    'RowName',{},...
                    'BackgroundColor',[0.9290 0.6940 0.1250],...
                    'ForegroundColor','blue');
                
                
                obj.handles.table_unilateralRight=uitable('Parent',fig1,'Units','normalized',...
                    'OuterPosition',[0.25 0 0.5 0.3],...
                    'ColumnEditable',[false false],...
                    'ColumnName','Unilateral Right',...
                    'RowName',{},...
                    'BackgroundColor',[0.9290 0.6940 0.1250],...
                    'ForegroundColor','blue');
                
                % The Data is been checked wheter there is some usefull
                % data or not and then the 5 highest results are choosen to
                % be displayed.
                
                if not(isempty(Actor.PredictInformation.Results{1}.bilateral))
                    obj.HighestResults.bilateral.results=maxk(Actor.PredictInformation.Results{1,1}.bilateral,obj.topScoreValue);
                    obj.HighestResults.bilateral.results=reshape(obj.HighestResults.bilateral.results,[1,(obj.topScoreValue*dimensionsOfPredictionResults)]);
                    obj.HighestResults.bilateral.results=unique(obj.HighestResults.bilateral.results);
                    obj.HighestResults.bilateral.results=maxk(obj.HighestResults.bilateral.results,obj.topScoreValue);
                    for itopScoreValue=1:obj.topScoreValue
                        obj.HighestResults.bilateral.position{itopScoreValue}=ismember(Actor.PredictInformation.Results{1,1}.bilateral,obj.HighestResults.bilateral.results(1,itopScoreValue));
                        [row,col]=find(obj.HighestResults.bilateral.position{itopScoreValue});
                        row=unique(row);
                        col=unique(col);
                        part='C%s-%smA';
                        if numel(row)>1 || numel(col)>1
                            part1=sprintf(part,num2str(contacts_vector(1,row(1,1))),num2str(amplitudes_vector(1,row(1,1))));
                            part2=sprintf(part,num2str(contacts_vector(1,col(1,1))),num2str(amplitudes_vector(1,col(1,1))));
                            for i=2:numel(row)
                                helpPart=sprintf(part,num2str(contacts_vector(1,row(i,1))),num2str(amplitudes_vector(1,row(i,1))));
                                part1=[part1,' or ',helpPart];
                            end
                            part1=[part1,'"l"'];
                            for i=2:numel(col)
                                helpPart=sprintf(part,num2str(contacts_vector(1,col(i,1))),num2str(amplitudes_vector(1,col(i,1))));
                                part2=[part2,' or ',helpPart];
                            end
                            part2=[part2,'"r"'];
                        else
                            part1=sprintf(part,num2str(contacts_vector(1,row)),num2str(amplitudes_vector(1,row)));
                            part2=sprintf(part,num2str(contacts_vector(1,col)),num2str(amplitudes_vector(1,col)));
                        end
                        obj.handles.table_bilateral.RowName{itopScoreValue}=sprintf([part1,'and',part2]);
                        obj.handles.table_bilateral.Data(itopScoreValue,1)=obj.HighestResults.bilateral.results(1,itopScoreValue);
                    end
                end
                
                if not(isempty(Actor.PredictInformation.Results{1, 1}.unilateral.left))
                    obj.HighestResults.unilateralLeft.results=unique(Actor.PredictInformation.Results{1,1}.unilateral.left);
                    obj.HighestResults.unilateralLeft.results=maxk(obj.HighestResults.unilateralLeft.results,obj.topScoreValue);
                    for itopScoreValue=1:obj.topScoreValue
                        obj.HighestResults.unilateralLeft.position{itopScoreValue}=ismember(Actor.PredictInformation.Results{1,1}.unilateral.left,obj.HighestResults.unilateralLeft.results(1,itopScoreValue));
                        [row,col]=find(obj.HighestResults.unilateralLeft.position{itopScoreValue});
                        row=unique(row);
                        col=unique(col);
                        part='C%s-%smA';
                        nameing=sprintf(part,num2str(contacts_vector(1,...
                            col(1,1))),num2str(amplitudes_vector(1,col(1,1))));
                        if numel(col)>1
                            for i=2:numel(col)
                                nameing2=sprintf(part,num2str(contacts_vector(1,...
                                    col(1,i))),num2str(amplitudes_vector(1,col(1,i))));
                                nameing=[nameing,' or ', nameing2];
                                obj.handles.table_unilateralLeft.RowName{itopScoreValue}=nameing;
                            end
                        end
                        obj.handles.table_unilateralLeft.RowName{itopScoreValue}=naming;
                        obj.handles.table_unilateralLeft.Data(itopScoreValue,1)=obj.HighestResults.unilateralLeft.results(1,itopScoreValue);
                    end
                end
                
                if not(isempty(Actor.PredictInformation.Results{1, 1}.unilateral.right))
                    obj.HighestResults.unilateralRight.results=unique(Actor.PredictInformation.Results{1,1}.unilateral.right);
                    obj.HighestResults.unilateralRight.results=maxk(obj.HighestResults.unilateralRight.results,obj.topScoreValue);
                    for itopScoreValue=1:obj.topScoreValue
                        obj.HighestResults.unilateralRight.position{itopScoreValue}=ismember(Actor.PredictInformation.Results{1,1}.unilateral.right,obj.HighestResults.unilateralRight.results(1,itopScoreValue));
                        [row,col]=find(obj.HighestResults.unilateralRight.position{itopScoreValue});
                        row=unique(row);
                        col=unique(col);
                        part='C%s-%smA';
                        nameing=sprintf(part,num2str(contacts_vector(1,...
                            col(1,1))),num2str(amplitudes_vector(1,col(1,1))));
                        if numel(col)>1
                            for i=2:numel(col)
                                nameing2=sprintf(part,num2str(contacts_vector(1,col(1,...
                                    i))),num2str(amplitudes_vector(1,col(1,i))));
                                nameing=[nameing,' or ', nameing2];
                                obj.handles.table_unilateralRight.RowName{itopScoreValue}=nameing;
                            end
                        end
                        obj.handles.table_unilateralRight.RowName{itopScoreValue}=naming;
                        obj.handles.table_unilateralRight.Data(itopScoreValue,1)=obj.HighestResults.unilateralRight.results(1,itopScoreValue);
                    end
                end
                
            elseif obj.devoloperOptions2==1
                
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
                if not(isempty(Actor.PredictInformation.Results{1, 1}.unilateral.left))
                    subplot(1,7,5)
                    img=imresize(img,0.5);
                    thisScene.handles.electrodeImage1=imshow(img);
                    set(gca,'Position',[0.43 0.1 0.2 0.7]);
                    greaterThanThresholdLeft=Actor.PredictInformation.confidenceLevel.leftSide.average>obj.treshhold;
                    greaterThanThresholdLeft=Actor.PredictInformation.Results{1,1}.unilateral.left.*greaterThanThresholdLeft;
                end
                if not(isempty(Actor.PredictInformation.Results{1, 1}.unilateral.right))
                    subplot(1,7,7)
                    thisScene.handles.electrodeImage2=imshow(img);
                    set(gca,'Position',[0.68 0.1 0.2 0.7]);
                    greaterThanThresholdRight=Actor.PredictInformation.confidenceLevel.rightSide.average>obj.treshhold;
                    greaterThanThresholdRight=Actor.PredictInformation.Results{1,1}.unilateral.right.*greaterThanThresholdRight;
                end
                numberOfContactsSettings=Actor.PredictInformation.configStructure.numberOfContactSettings;
                for i=1:4
                    %get the highest prediction result per contact
                    ypos=0.19+(i-1)*0.109;
                    try
                        if  not(isempty(Actor.PredictInformation.Results{1, 1}.unilateral.left))
                            maxForContactLeft=maxk(greaterThanThresholdLeft(1+numberOfContactsSettings*(i-1):numberOfContactsSettings*i),1);
                            maxForContactLeft=unique(maxForContactLeft);
                            positionOfNumberInVector=find(greaterThanThresholdLeft(1+numberOfContactsSettings*(i-1):numberOfContactsSettings*i)==maxForContactLeft);
                            valueOfStimulationLeft=amplitudes_vector(1,positionOfNumberInVector(1,1));
                            if maxForContactLeft<1
                                xlengthLeft=0.02+maxForContactLeft/8;
                            else
                                xlengthLeft=0.02+maxForContactLeft/800;
                            end
                            positionLeft=[0.546 ypos xlengthLeft 0.08];
                            thisScene.handles.barLeft.num2str(i)=uicontrol('parent',thisScene.handles.figure,...
                                'Style','text',...
                                'BackgroundColor','g',...
                                'Units','normalized',...
                                'Position',positionLeft,...
                                'String',num2str(maxForContactLeft));
                            positionLeft=[0.546+xlengthLeft ypos 0.04 0.08];
                            thisScene.handles.barTextLeft.num2str(i)=uicontrol('parent',thisScene.handles.figure,...
                                'Style','text',...
                                'BackgroundColor',[0.4660, 0.6740, 0.1880],...
                                'Units','normalized',...
                                'Position',positionLeft,...
                                'String',[num2str(valueOfStimulationLeft),'mA']);
                        end
                    catch
                    end

                        if not(isempty(Actor.PredictInformation.Results{1, 1}.unilateral.right))
                            maxForContactRight=maxk(greaterThanThresholdRight(1+numberOfContactsSettings*(i-1):numberOfContactsSettings*i),1);
                            positionOfNumberInVector=find(greaterThanThresholdRight(1+numberOfContactsSettings*(i-1):numberOfContactsSettings*i)==maxForContactRight);
                            valueOfStimulationRight=amplitudes_vector(1,positionOfNumberInVector(1,1));
                            maxForContactRight=unique(maxForContactRight);
                            if maxForContactRight<1
                                xlengthRight=0.02+maxForContactRight/8;
                            else
                                xlengthRight=0.02+maxForContactRight/800;
                            end
                            positionRight=[0.798 ypos xlengthRight 0.08];
                            %construct the reference bar
                            thisScene.handles.barRight.num2str(i)=uicontrol('parent',thisScene.handles.figure,...
                                'Style','text',...
                                'BackgroundColor','g',...
                                'Units','normalized',...
                                'Position',positionRight,...
                                'String',num2str(maxForContactRight));
                            positionRight=[0.798+xlengthRight ypos 0.04 0.08];
                            thisScene.handles.barTextRight.num2str(i)=uicontrol('parent',thisScene.handles.figure,...
                                'Style','text',...
                                'BackgroundColor',[0.4660, 0.6740, 0.1880],...
                                'Units','normalized',...
                                'Position',positionRight,...
                                'String',[num2str(valueOfStimulationRight),'mA']);
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


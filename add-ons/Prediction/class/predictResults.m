classdef predictResults<handle
    %This class is used for displaying diganosed results of predictions. It
    %can give the unilateral and bilateral top choosen results in combination
    %or without.
    
    properties
        handles
        HighestResults
    end
    
    methods
        function obj = predictResults()
            %this needs to be here
        end
        
        function displayHighestResults(obj,Actor)
            
            answer=5; % If in in the future this an other value is needed, you can add the outcomings here.
            
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

            fig1=figure('Units','normalized','Position',[0.05 0 0.9 0.9],'Name','Results');
            table_bilateral=uitable('Parent',fig1,'Units','normalized',...
                'OuterPosition',[0.05 0.64 0.9 0.3],...
                'ColumnEditable',[false false],...
                'ColumnName','Bilateral',...
                'RowName',{},...
                'BackgroundColor',[0.9290 0.6940 0.1250],...
                'ForegroundColor','blue');
            

            table_unilateralLeft=uitable('Parent',fig1,'Units','normalized',...
                'OuterPosition',[0.25 0.32 0.5 0.3],...
                'ColumnEditable',[false false],...
                'ColumnName','Unilateral Left',...
                'RowName',{},...
                'BackgroundColor',[0.9290 0.6940 0.1250],...
                'ForegroundColor','blue');
            
            
            table_unilateralRight=uitable('Parent',fig1,'Units','normalized',...
                'OuterPosition',[0.25 0 0.5 0.3],...
                'ColumnEditable',[false false],...
                'ColumnName','Unilateral Right',...
                'RowName',{},...
                'BackgroundColor',[0.9290 0.6940 0.1250],...
                'ForegroundColor','blue');
            
            % The Data is been checked wheter there is some usefull
            % data or not and then the 5 highest results are choosen to
            % be displayed.
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
            
            if not(isempty(Actor.PredictInformation.Results{1}.bilateral))
                obj.HighestResults.bilateral.results=maxk(Actor.PredictInformation.Results{1,1}.bilateral,answer);
                obj.HighestResults.bilateral.results=reshape(obj.HighestResults.bilateral.results,[1,(answer*dimensionsOfPredictionResults)]);
                obj.HighestResults.bilateral.results=unique(obj.HighestResults.bilateral.results);
                obj.HighestResults.bilateral.results=maxk(obj.HighestResults.bilateral.results,answer);
                for ianswer=1:answer
                    obj.HighestResults.bilateral.position{ianswer}=ismember(Actor.PredictInformation.Results{1,1}.bilateral,obj.HighestResults.bilateral.results(1,ianswer));
                    [row,col]=find(obj.HighestResults.bilateral.position{ianswer});
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
                    table_bilateral.RowName{ianswer}=sprintf([part1,'and',part2]);
                    table_bilateral.Data(ianswer,1)=obj.HighestResults.bilateral.results(1,ianswer);
                end
            end
            
            if not(isempty(Actor.PredictInformation.Results{1, 1}.unilateral.left))
                obj.HighestResults.unilateralLeft.results=unique(Actor.PredictInformation.Results{1,1}.unilateral.left);
                obj.HighestResults.unilateralLeft.results=maxk(obj.HighestResults.unilateralLeft.results,answer);
                for ianswer=1:answer
                    obj.HighestResults.unilateralLeft.position{ianswer}=ismember(Actor.PredictInformation.Results{1,1}.unilateral.left,obj.HighestResults.unilateralLeft.results(1,ianswer));
                    [row,col]=find(obj.HighestResults.unilateralLeft.position{ianswer});
                    row=unique(row);
                    col=unique(col);
                    part='C%s-%smA';
                    if numel(col)>1
                        nameing=sprintf(part,num2str(contacts_vector(1,...
                            col(1,1))),num2str(amplitudes_vector(1,col(1,1))));
                         for i=2:numel(col)
                        nameing2=sprintf(part,num2str(contacts_vector(1,...
                            col(1,i))),num2str(amplitudes_vector(1,col(1,i))));
                        nameing=[nameing,' or ', nameing2]
                        table_unilateralLeft.RowName{ianswer}=nameing;
                         end
                    else
                        table_unilateralLeft.RowName{ianswer}=sprintf(part,num2str(contacts_vector(1,...
                            col)),num2str(amplitudes_vector(1,col)));
                    end
                    table_unilateralLeft.Data(ianswer,1)=obj.HighestResults.unilateralLeft.results(1,ianswer);
                end
            end
            
            if not(isempty(Actor.PredictInformation.Results{1, 1}.unilateral.right))
                obj.HighestResults.unilateralRight.results=unique(Actor.PredictInformation.Results{1,1}.unilateral.right);
                obj.HighestResults.unilateralRight.results=maxk(obj.HighestResults.unilateralRight.results,answer);
                for ianswer=1:answer
                    obj.HighestResults.unilateralRight.position{ianswer}=ismember(Actor.PredictInformation.Results{1,1}.unilateral.right,obj.HighestResults.unilateralRight.results(1,ianswer));
                    [row,col]=find(obj.HighestResults.unilateralRight.position{ianswer});
                    row=unique(row);
                    col=unique(col);
                    part='C%s-%smA';
                    if numel(col)>1
                        nameing=sprintf(part,num2str(contacts_vector(1,...
                            col(1,1))),num2str(amplitudes_vector(1,col(1,1))));
                         for i=2:numel(col)
                        nameing2=sprintf(part,num2str(contacts_vector(1,col(1,...
                            i))),num2str(amplitudes_vector(1,col(1,i))));
                        nameing=[nameing,' or ', nameing2]
                        table_unilateralRight.RowName{ianswer}=nameing;
                         end
                    else
                        table_unilateralRight.RowName{ianswer}=sprintf(part,num2str(contacts_vector(1,...
                            col)),num2str(amplitudes_vector(1,col)));
                    end
                    table_unilateralRight.Data(ianswer,1)=obj.HighestResults.unilateralRight.results(1,ianswer);
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
end


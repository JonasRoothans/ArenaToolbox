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
            
            obj.handles.showResultsWindow=figure('units','normalized',...
                'outerposition',[0.25 0.25 0.8 0.2],...
                'menubar','none',...
                'name',['Result ', Actor.Tag],...
                'numbertitle','off',...
                'resize','off',...
                'WindowKeyPressFcn',@kSnapshotResult,...
                'Color',[1 1 1]);
            
            obj.handles.table_bilateral=uitable('Parent',obj.handles.showResultsWindow,...
                'Units','normalized',...
                'OuterPosition',[0.05 0 0.4 1],...
                'ColumnEditable',[false false],...
                'ColumnName','Bilateral',...
                'RowName',{},...
                'BackgroundColor',[0.9290 0.6940 0.1250],...
                'ForegroundColor','blue');
            
            obj.handles.table_unilateralLeft=uitable('Parent',obj.handles.showResultsWindow,...
                'Units','normalized',...
                'OuterPosition',[0.46 0 0.3 1],...
                'ColumnEditable',[false false],...
                'ColumnName','Unilateral Left',...
                'RowName',{},...
                'BackgroundColor',[0.9290 0.6940 0.1250],...
                'ForegroundColor','blue');
            
            obj.handles.table_unilateralRight=uitable('Parent',obj.handles.showResultsWindow,...
                'Units','normalized',...
                'OuterPosition',[0.77 0 0.3 1],...
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
            contacts_vector=Actor.PredictInformation.configStructure.contacts_vector;
            amplitudes_vector=Actor.PredictInformation.configStructure.amplitudes_vector;
            
            if not(isempty(Actor.PredictInformation.Results{1}.bilateral))
                obj.HighestResults.bilateral.results=maxk(Actor.PredictInformation.Results{1,1}.bilateral,answer);
                obj.HighestResults.bilateral.results=reshape(obj.HighestResults.bilateral.results,[1,(answer*20)]);
                obj.HighestResults.bilateral.results=maxk(obj.HighestResults.bilateral.results,answer);
                for ianswer=1:answer
                    obj.HighestResults.bilateral.position{ianswer}=ismember(Actor.PredictInformation.Results{1,1}.bilateral,obj.HighestResults.bilateral.results(1,ianswer));
                    [row,col]=find(obj.HighestResults.bilateral.position{ianswer});
                    part='C%d-%dmA';
                    part1=sprintf(part,contacts_vector(1,row),amplitudes_vector(1,row));
                    part2=sprintf(part,contacts_vector(1,col),amplitudes_vector(1,col));
                    obj.handles.table_bilateral.RowName{ianswer}=sprintf([part1,'and',part2]);
                    obj.handles.table_bilateral.Data(ianswer,1)=obj.HighestResults.bilateral.results(1,ianswer);
                end
            end
            
            if not(isempty(Actor.PredictInformation.Results{1, 1}.unilateral.left))
                obj.HighestResults.unilateralLeft.results=maxk(Actor.PredictInformation.Results{1,1}.unilateral.left,answer);
                for ianswer=1:answer
                    obj.HighestResults.unilateralLeft.position{ianswer}=ismember(Actor.PredictInformation.Results{1,1}.unilateral.left,obj.HighestResults.unilateralLeft.results(1,ianswer));
                    [row,col]=find(obj.HighestResults.unilateralLeft.position{ianswer});
                    part='C%d-%dmA';
                    obj.handles.table_unilateralLeft.RowName{ianswer}=sprintf(part,contacts_vector(1,...
                        col),amplitudes_vector(1,col));
                    obj.handles.table_unilateralLeft.Data(ianswer,1)=obj.HighestResults.unilateralLeft.results(1,ianswer);
                end
            end
            
            if not(isempty(Actor.PredictInformation.Results{1, 1}.unilateral.right))
                 obj.HighestResults.unilateralRight.results=maxk(Actor.PredictInformation.Results{1,1}.unilateral.right,answer);
                for ianswer=1:answer
                    obj.HighestResults.unilateralRight.position{ianswer}=ismember(Actor.PredictInformation.Results{1,1}.unilateral.right,obj.HighestResults.unilateralRight.results(1,ianswer));
                    [row,col]=find(obj.HighestResults.unilateralRight.position{ianswer});
                    part='C%d-%dmA';
                    obj.handles.table_unilateralRight.RowName{ianswer}=sprintf(part,contacts_vector(1,...
                        col),amplitudes_vector(1,col));
                    obj.handles.table_unilateralRight.Data(ianswer,1)=obj.HighestResults.unilateralRight.results(1,ianswer);
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



classdef Heatmap < handle
    %HEATMAP Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = Heatmap()
            %HEATMAP Construct an instance of this class
            %   Detailed explanation goes here
            
        end
        
    end
    
    methods (Static)
        function printPredictionList(Tag,predictionList,pairs,blackOrRed)
            fileID = Heatmap.makeFile(Tag);
            
            [sorted,order] = sort(vertcat(predictionList.Output),'descend');
                        
        %----two leads
            if length(size(pairs))==2
                Heatmap.printtext(fileID,'\t\t\t%s\t%s\n',predictionList(1).Input.VTAs(1).ActorElectrode.Tag,predictionList(1).Input.VTAs(2).ActorElectrode.Tag);
                Heatmap.printtext(fileID,'-------------------------------------------\n')
                for iShortlist = 1:length(order)
                    item = order(iShortlist);
                    Improv = predictionList(item).Output;
                    c_e1 = predictionList(item).Input.VTAs(1).Settings.activecontact;
                    c_e2 = predictionList(item).Input.VTAs(2).Settings.activecontact;
                    a_e1 = predictionList(item).Input.VTAs(1).Settings.amplitude;
                    a_e2 = predictionList(item).Input.VTAs(2).Settings.amplitude;
                    conf_e1 = predictionList(item).Confidence(1);
                    conf_e2 = predictionList(item).Confidence(2);
                   
                    Heatmap.printtext(fileID,'%i.\t %2.1f \t C%i - %2.1f mA\t C%i - %2.1f mA \t (%2.2f / %2.2f) \n',iShortlist,Improv, c_e1,a_e1,c_e2,a_e2,conf_e1,conf_e2);

                end
            else
                
    %----one lead
                for iShortlist = 1:length(order)
                    %                 thisPair = ReviewData.pairs(order(iShortlist),:);
                    item = order(iShortlist);
                    Improv = predictionList(item).Output;
                    c_e1 = predictionList(item).Input.VTAs(1).Settings.activecontact;
                    a_e1 = predictionList(item).Input.VTAs(1).Settings.amplitude;
                    conf_e1 = predictionList(item).Confidence(1);
                    
                    Heatmap.printtext(fileID,'%i.\t %2.1f \t C%i - %2.1f mA\t (%2.2f) \n',iShortlist,Improv, c_e1,a_e1,conf_e1);
                    
                end
            end
            
            fclose(fileID);

        end
            function printtext(fid,varargin)
                fprintf(fid,varargin{:});
                fprintf(varargin{:});
            end
        function fileID = makeFile(Tag)
            %make export directory
            p = mfilename('fullpath');
            arenaDir= fileparts(fileparts(p));
            currentDir = fullfile(arenaDir,'UserData','Monpolar Review',Tag);
            [~,msg] = mkdir(currentDir);
            counter = 1;
            while strcmp(msg,'Directory already exists.')
                currentDir = fullfile(arenaDir,'UserData','Monpolar Review',[Tag,' (',num2str(counter),')']);
                [~,msg] = mkdir(currentDir);
                counter = counter+1;
            end
            
            %open file
            fileID = fopen(fullfile(currentDir,'RankedScores.txt'),'w');
        end
    end
end


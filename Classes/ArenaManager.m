classdef ArenaManager < handle
    %ARENAMANAGER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Scenes = ArenaScene.empty;
    end
    
    methods
        function [obj, thisScene] = ArenaManager()
            %ARENAMANAGER Construct an instance of this class
            %   Detailed explanation goes here
            
            if not(obj.hasscene)
                answer = questdlg('How do you want to start?','Arena','Open scene','New scene','New scene');
                switch answer
                    case 'Open scene'
                        [filename,pathname] = uigetfile('*.scn');
                        loaded = load(fullfile(pathname,filename),'-mat');
                        thisScene = loaded.Scene;
                        keyboard
                    case 'New scene'
                        [thisScene] = obj.new();

                end
            end
            
        end
        
        %-- booleans
        function bool = hasscene(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            bool = not(isempty(obj.Scenes));
        end
        
        %--- functions
        
        function newScene = new(obj,OPTIONALname)
            newScene = ArenaScene();
            newScene.create(OPTIONALname);
            obj.Scenes(end+1) = newScene;
        end
        
        
        function scenehandle = sceneselect(obj,index)
            if nargin==1 %If selection is not input argument
                options = {};
                for i = 1:numel(obj.Scenes)
                    options{end+1} = obj.Scenes(i).Title;
                end
                options{end+1} = 'other...';
                
                index = listdlg('ListString',options,'ListSize',[200,100],'SelectionMode','single');
                
                %make new scene when selected
                if index>numel(obj.Scenes)
                    newScene = ArenaScene();
                    newScene.create();
                    obj.Scenes(end+1) = newScene;
                end
            end
            scenehandle = obj.Scenes(index);
            
        end
        
    end
end


classdef ArenaManager < handle
    %ARENAMANAGER Manages instances of Scenes.
    
    properties
        Scenes = ArenaScene.empty;
    end
    
    methods
        function [obj, thisScene] = ArenaManager()
            %ARENAMANAGER Construct an instance of this class
            %   Detailed explanation goes here
            
            %check if a setupfile exists.
            ArenaFolder = ArenaManager.getrootdir();
            if not(exist('config.mat','file'))
                ArenaManager.setup(ArenaFolder);
            end
                
            
            
            if not(obj.hasscene)
                answer = questdlg('How do you want to start?','Arena','Open scene','New scene','New scene');
                switch answer
                    case 'Open scene'
                        [filename,pathname] = uigetfile('*.scn');
                        loaded = load(fullfile(pathname,filename),'-mat');
                        thisScene = loaded.Scene;
                         obj.Scenes(end+1) = thisScene;
                        
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
            if nargin==1
            newScene.create();
            elseif nargin==2
                newScene.create(OPTIONALname);
            end
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
    
    methods (Static)
        function setup(rootdir)
            waitfor(msgbox('Arena uses atlases that are available in leadDBS. Please select the lead DBS folder'))
            leadDBSdir = uigetdir('Find leadDBS dir');
            
            if isempty(leadDBSdir)
                error('aborted by user')
            end
            
            config.leadDBS = leadDBSdir;
            save(fullfile(rootdir,'config.mat'),'config')
        end
        
        function rootdir = getrootdir()
            rootdir = fileparts(fileparts(mfilename('fullpath')));
        end
    end
end



classdef ArenaManager < handle
    %ARENAMANAGER Manages instances of Scenes.
    
    properties
        Scenes = ArenaScene.empty;
    end
    
    properties(Hidden)
        DIPS = false;
        Settings
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
            
            %Add SDK to the path
            load(fullfile(ArenaFolder,'config.mat'));
            obj.Settings = config;
            
            
            warning('off','all')
            addpath(genpath(config.SDKdir))
            warning('on','all')
            
            
            
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
        
        
        function scenehandle = sceneselect(obj,index,txt)
            if nargin==1 || isempty(index) %If selection is not input argument
                options = {};
                for i = 1:numel(obj.Scenes)
                    options{end+1} = obj.Scenes(i).Title;
                end
                options{end+1} = 'other...';
                
                if nargin<3
                    index = listdlg('ListString',options,'ListSize',[200,100],'SelectionMode','single');
                elseif nargin==3
                    index = listdlg('ListString',options,'ListSize',[200,100],'SelectionMode','single','PromptString',txt);
                end
                %make new scene when selected
                if index>numel(obj.Scenes)
                    newScene = ArenaScene();
                    newScene.create();
                    obj.Scenes(end+1) = newScene;
                end
            end
           
                scenehandle = obj.Scenes(index);
        end
        
        function enableVTAhack(obj)
            obj.Settings.VTAhack = true;
            config = obj.Settings;
            save(fullfile(config.rootdir,'config.mat'),'config')
            disp('VTA hack is enabled, and preference is saved.')
        end
            
        function triggerDIPS(obj)
           
            for iScene = 1:numel(obj.Scenes)
                thisScene = obj.Scenes(iScene);
                menuHandle = obj.Scenes(iScene).handles.menu.file.DIPSmode;
                if obj.DIPS
                    set(thisScene.handles.figure,'Color',[1 1 1])       
                    menuHandle.Checked = 'off';
                else
                    set(thisScene.handles.figure,'Color',[255, 207, 158]/255)   
                    menuHandle.Checked = 'on';
                    
                end
               
            end
            if obj.DIPS
                obj.DIPS = false;
            else
                obj.DIPS = true;
            end
            
        end

        
    end
    
    
    methods (Static)
        function  success = setup(rootdir)
            %--- leadDBS
            waitfor(msgbox('Arena uses atlases that are available in leadDBS. Please select the lead DBS folder'))
            leadDBSdir = uigetdir('Find leadDBS directory');
            
            if not(leadDBSdir)
                error('aborted by user')
            end
            
            config.leadDBS = leadDBSdir;
            %---- SDK
            waitfor(msgbox('Arena uses nifti tools that are available in the SuretuneSDK. Please select the lead SDK folder'))
            SDKdir = uigetdir('Find SuretuneSDK directory');
            
            if not(SDKdir)
                error('aborted by user')
            end
            config.SDKdir = SDKdir;
            
            %---- Sweetspotstation
            waitfor(msgbox('Arena uses a "VTAPOOL" to store VTAs for predictions etc. Please select or create the folder'))
            VTAdir = uigetdir('Find the VTApool directory');
            
            if not(VTAdir)
                error('aborted by user')
            end
            config.VTApool = VTAdir;
            
            
            %--- VTAhack
            answer = questdlg('Do you want to enable VTApool enhancement? This will approximate missing VTAs in the pool. Accuracy is compromised.','Advanced VTA method');
            switch answer
                case 'yes'
                    config.VTAhack = true;
                otherwise
                    config.VTAhack = false;
            end
            
            %---- save config file
            config.rootdir = rootdir;
            save(fullfile(rootdir,'config.mat'),'config')
        end
        
        
            
        
        
        function rootdir = getrootdir()
            rootdir = fileparts(fileparts(mfilename('fullpath')));
        end
        
        
    end
end


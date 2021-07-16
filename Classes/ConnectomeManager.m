classdef ConnectomeManager < handle
    %CONNECTOMEMANAGER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Connectomes = Connectome.empty;
    end
    
    methods
        function obj = ConnectomeManager()
            %CONNECTOMEMANAGER Construct an instance of this class
            %   Detailed explanation goes here
        
                %Use ArenaManager config file
                ArenaFolder = ArenaManager.getrootdir();
                if not(exist('config.mat','file'))
                    ArenaManager.setup(ArenaFolder);
                end
                
        end
            
        
        
        function addPathList(obj,connectomePathList)
            %pathlist contains the stored paths to the connectomes from the
            %config file
            for iConnectome = 1:numel(connectomePathList)
                %create Connectome objects
                path_and_id = connectomePathList(iConnectome);
                
                %empty object
                newC = Connectome;
                
                %enter path and id (NO DATA) and add to the manager
                obj.Connectomes(end+1) = newC.linkToFile(path_and_id);
            end
        end
        
       
        
        function c = selectConnectome(obj,index)
            obj.setup(); %fills up the Connectome-list
            %loop over connectomes, and list all the names
            if nargin ==2
                c = obj.Connectomes(index).cache;
                return
            end
            
            
            idlist = {};
            for iC = 1:numel(obj.Connectomes)
                thisC = obj.Connectomes(iC);
                
                id = thisC.ID;
                if not(isempty(thisC.Data))
                    id = ['>> ',id];
                else
                    id = ['__ ',id];
                end
                idlist{iC} = id;
            end
            
            idlist{end+1} = 'other...';
            index = listdlg('ListString',idlist,'ListSize',[400,100],'SelectionMode','single');
                
                %make new connectome when selected
                if index>numel(obj.Connectomes)
                    [connectomeName,connectomePath] = uigetfile('*.mat');
                    [~, idsuggestion] = fileparts(connectomePath(1:end-1));
                    userinput = newid({'Store connectome in memory as: '},'Arena',1,{idsuggestion});
                    
                    %add it to the config file
                     ArenaFolder = ArenaManager.getrootdir();
                     load(fullfile(ArenaFolder,'config.mat'));
                    config.connectomePathList(end+1).path = fullfile(connectomePath,connectomeName);
                    config.connectomePathList(end).id = userinput{1};
                    save(fullfile(ArenaFolder,'config.mat'),'config');
                    
                    %make new connectome object
                    load_this_connectome = Connectome;
                    load_this_connectome.linkToFile(config.connectomePathList(end))
                    obj.Connectomes(end+1) = load_this_connectome;
                    
                else
                    load_this_connectome = obj.Connectomes(index);
                end
            
            
                  c = load_this_connectome.cache;
                
            end
            
    

   
    
         function obj = setup(obj)
            ArenaFolder = ArenaManager.getrootdir();
            
            %at first run the list is empty and needs to be loaded, or
            %created
            if isempty(obj.Connectomes)
                load(fullfile(ArenaFolder,'config.mat'));
                if isfield(config,'connectomePathList')
                    obj.addPathList(config.connectomePathList);
                else
                    
                    waitfor(msgbox('Please find your connectome'))
                    
                    
                    [connectomeName,connectomePath] = uigetfile('*.mat');
                    [~, idsuggestion] = fileparts(connectomePath(1:end-1));
                    userinput = newid({'Store connectome in memory as: '},'Arena',1,{idsuggestion});
                    
                    %since the pathlist did not exist: make a new
                    config.connectomePathList(1).path = fullfile(connectomePath,connectomeName);
                    config.connectomePathList(1).id = userinput{1};
                    save(fullfile(ArenaFolder,'config.mat'),'config');
                    
                    %and sync it with the manager
                    obj.addPathList(config.connectomePathList);
                   

                end
            else
                
                disp('Manager was already running')
            end
            
         end
    end
        

        
    methods (Static)
    end
       
    
end


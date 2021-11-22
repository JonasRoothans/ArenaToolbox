classdef Heatmap < handle 
    
    properties
        Tag
        Tmap
        Pmap
        Signedpmap
        Amap
        Cmap
        Rmap
        Fzmap
        Raw
        Description
        
    end
    
    properties (Hidden)
        outputdir
    end
        
    
    methods
        function obj = Heatmap()
            
        end
        
        %---- MAKE THIS----convert heatmap from VoxelDataStack- LOO in
        %LOORoutine
        function obj =  fromVoxelDataStack(obj,StackedData,filename)
            
            if nargin<2
                Stack=VoxelDataStack;
                answer = questdlg('how do you like to load the data?','select Data to load',...
                    'from Recipe','all subject Files in Folder',...
                    'files in subfolders','from Recipe');
                switch answer
                    case 'from Recipe'
                        try
                            Stack.loadStudyDataFromRecipe();
                        catch
                            error('something went wrong, currently no support for old recipe files');
                        end
                    case 'all subject Files in Folder'
                        
                        Stack.loadDataFromFolder();
                        % incomplete
                    case 'files insubfolders'
                        selpath = uigetdir([],'select parent folder');
                        subfolders_dir=A_getsubfolders(selpath);
                        % incomplete
                end
            else
                if ~isequal(class(StackedData), 'VoxelDataStack')
                    warning(' first argument class type is not compatible, please folllow prompts to load data properly:')
                    
                end
                Stack=StackedData;
            end
            
             if nargin<3
                    filename= inputdlg('enter name/description:');
                end
            
            
%             global arena
%             if not(isfield(arena.Settings,'rootdir'))
%                 error('Your settings file is outdated. Please remove config.mat and restart MATLAB for a new setup')
%             end
            
%             if nargin<3
%                 error('Include the heatmapname and a short description!')
%             end
%             
%             if nargin<4
%                savememory = false;
%             end
%             

          
            [tmap,pmap,signedpmap] = Stack.ttest2();
            
            obj.Tmap = tmap;
            obj.Pmap = pmap;
            obj.Signedpmap = signedpmap;
            obj.Description = filename;
            obj.outputdir=Stack.RecipePath;
%           obj.VoxelDataStack = Stack;
            
            
            %save....%%% to be removed in the future and only saved through
            %heatmap cook function.
            
%             outputdir = fullfile(arena.Settings.rootdir,'HeatmapOutput');
%             
%             
%             publicProperties = properties(heatmap); % convert from class heatmap to struct to be able to save without changing properties
%             exportheatmap = struct();
%             for iField = 1:numel(publicProperties)
%                 exportheatmap.(publicProperties{iField}) = heatmap.(publicProperties{iField});
%             end
%             
%             save(fullfile(outputdir,[filename,'.heatmap']),'-struct','exportheatmap','-v7.3')

               
           
        
        end
            
 
       function fz = makeFzMap(obj)
            if not(isempty(obj.Fzmap))
                fz = obj.Fzmap;
                return
            end
            if isempty(obj.Rmap)
                error('requires an rmap')
            end
            
            fzVoxels = atanh(obj.Rmap.Voxels);
            obj.Fzmap = VoxelData(fzVoxels,obj.Rmap.R);
        end
        
        function newObj = copy(obj)
            newObj = Heatmap();
            props = properties(obj);
            for iProp = 1:numel(props)
                if isempty(obj.(props{iProp}))
                    newObj.(props{iProp}) = [];
                else
                    if isa(obj.(props{iProp}),'handle')
                        try
                        newObj.(props{iProp}) = copy(obj.(props{iProp}));
                        catch
                            keyboard
                        end
                    else
                        
                        newObj.(props{iProp}) = obj.(props{iProp});
                    end
                end
            end
          
        end
        
        function loadHeatmap(obj,hmpath)
            if nargin==1
                [filename,foldername] = uigetfile('*.nii;*.swtspt;*.heatmap','Get heatmap file');
                hmpath = fullfile(foldername,filename);
            end
            
            [~,~,ext] = fileparts(hmpath);
            switch ext
                case '.nii'
                    vd = VoxelData(hmpath);
                    [maps,mapsWithContents] = obj.getMapOverview();
                    val = listdlg('ListString',mapsWithContents,'PromptString','What kind of map is this?');
                    obj.(maps{val}) = vd;
                case '.swtspt'
                    error('Currently Heatmap is not yet backwards compatible. But if this is required. Let me know. -Jonas')
                case '.heatmap'
                    hm = load(hmpath,'-mat');
                    if isfield(hm,'hm')
                        hm = hm.hm;
                    end
                    props = properties(hm);
                    for iprop = 1:numel(props)
                        thisProp = props{iprop};
                        if isprop(obj,thisProp)
                            if not(isempty(obj.(thisProp)))
                                warning(['overwriting ',thisProp]);
                            end
                            obj.(thisProp) = hm.(thisProp);
                        end
                    end
            end
            
        end
        
        function [maps,mapsWithContents] = getMapOverview(obj)
            maps = {};
            mapsWithContents = {};
            props = properties(obj);
            for p = 1:length(props)
                if contains(props{p},'map')
                    maps{end+1} = props{p};
                    sz = size(obj.(props{p}));
                    if prod(sz)==0
                        sz_string = '__________';
                    else
                        sz_string = '[1 volume]';
                    end
                    mapsWithContents{end+1} = [sz_string,': ',props{p}];
                end
            end
        end
        
        %save function, to be called by heatmap_cook.. saves without
        %memory... save function to be added to to voxeldatastack and
        %LOOroutin 
        
        function obj=save(obj,outputdir)
            
            if isempty(obj.Description)
                
                input= inputdlg('enter description:');
                obj.Description=input;
            end
            
            if nargin<2
                outputdir=obj.outputdir;
            end
            
            [outfolder,file]=fileparts(outputdir);
            
         
            
            publicProperties = properties(obj); % convert from class heatmap to struct to be able to save without changing properties
            exportheatmap = struct();
            for iField = 1:numel(publicProperties)
                exportheatmap.(publicProperties{iField}) = obj.(publicProperties{iField});
            end

            filename=obj.Description;   
                
            save(fullfile(outfolder,[filename,'.heatmap']),'-struct','exportheatmap','-v7.3');
        end
  
        
        
        
        
        
        
        
        
%         function save(obj,filename, memory)
%             %voxelstack is not saved by default as it is very big.
%             %thisHeatmap.save('filename.heatmap','memory') will save
%             %memory.
%             save_memory = 0;
%             if nargin==3
%                 if strcmp(memory,'memory')
%                     save_memory = 1;
%                 end
%             end
%             
%             if nargin==1
%                 if not(isempty(obj.Tag))
%                     [fname,pname] = uiputfile([obj.Tag,'.heatmap']);
%                 else
%                     [fname,pname] = uiputfile('*.heatmap');
%                 end
%                 filename = fullfile(pname,fname);
%             end
%                 
%             %make a new version without the VoxelDataStack to save memory.
%             hm = copy(obj);
%             hm.VoxelDataStack = [];
%             
%             
%              %write heatmap
%             [folder,file,~] = fileparts(filename);
%             out.hm = hm;
%             save(fullfile(folder,[file,'.heatmap']),'-struct','out');
%             
%             %write memory
%             if save_memory
%                 out.hm.VoxelDataStack = obj.VoxelDataStack;
%                 save(fullfile(folder,[file,'_wVDS.heatmap']),'-struct','out','-v7.3')
%             end
%             
%             Done;
%         end
      
        
    end
    
    
    
end


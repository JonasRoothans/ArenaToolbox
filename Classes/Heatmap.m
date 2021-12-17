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
        Nmap
        %Raw  - remove?
        Description
        
    end
    
    properties (Hidden)
        outputdir
    end
        
    
    methods
        function obj = Heatmap()
            
            
        end
       
        
        function imref = R(obj)
            %find which maps exists
            [~,~,map] = obj.getMapOverview;
            if isempty(map)
                error('Heatmap is empty')
            end
            imref = map{1}.R;
        end
        
        
        function bool = has(obj,required)
            [maplabels,mapsWithContents,maps,index] = getMapOverview(obj);
            existing = maplabels(index);
            inCommon = intersect(existing,required);
            if length(inCommon) == length(required)
                bool = true;
            else
                missing = find(not(cellfun(@(x) contains(x,inCommon),required)));
                for m = 1:length(missing)
                    fprintf(2,[required{m},' is not available within this Heatmap.\n'])
                end
                error('Heatmap does not contain the required data for this Sampling Method')
                bool = false;
            end
                
                
            
            
      
        end
        
        
        function obj =  fromVoxelDataStack(obj,Stack,tag, description,mapSelection)
            
            if nargin<2
                Stack=VoxelDataStack;
                Stack.construct(); % this will prompt the question on how to load

            else
                if ~isa(Stack,'VoxelDataStack')
                    error(['Was expecting a VoxelDataStack as input argument instead of ',class(Stack)])
                end
                
            end
            
             if nargin<3
                    [~,nameSuggestion] = fileparts(Stack.RecipePath);
                    [out]= inputdlg({'tag','Description'},'Need info',[1 50; 3 50],{nameSuggestion,''});
                    if isempty(out)
                        tag = 'no name';
                        description = 'no description';
                    end
                    tag = out{1};
                    description = out{2};
             end
             
             if nargin<5
                 mapSelection = {'all'};
             end
             
             
             %n-map will always be computed.
             disp(' ~running count')
             obj.Nmap = Stack.count();
             

            %Wuerzburg-workflow
            if ~isempty(intersect(mapSelection,{'all','Signedpmap','Pmap','Tmap'}))
            [tmap,pmap,signedpmap] = Stack.ttest2();
            obj.Tmap = tmap;
            obj.Pmap = pmap;
            obj.Signedpmap = signedpmap;
            end

            %Berlin-workflow
            if ~isempty(intersect(mapSelection,{'all','Amap','Cmap','Rmap'}))
                if 0 %temporarily disabled
                    [amap,cmap,rmap] = Stack.berlinWorkflow;
                    obj.Amap = amap;
                    obj.Cmap = cmap;
                    obj.Rmap = rmap;
                end
            end
            

            
            obj.Tag = tag;
            obj.Description = description;
            obj.outputdir=Stack.RecipePath;

        end
            
        function see(obj,scene)
            
            props = properties(obj);
            options = {};
            for iProp = 1:numel(props)
                if isa(obj.(props{iProp}),'VoxelData')
                    options{end+1} =props{iProp};
                end
            end

            [indx] = listdlg('ListString',options,...
                'PromptString',obj.Description,...
                'ListSize',[250,150]);

            if nargin==1
                scene = getScene();
            end
            for i = indx
                thisProp = options{i};
                vd = obj.(thisProp);
                actor = vd.getslice.see(scene);
                actor.changeName([obj.Tag,'__',thisProp])
            end
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
            fz = obj.Fzmap;
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
                waitfor(msgbox('Select a heatmap file'))
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
                    if isfield(hm,'heatmap')
                        hm = hm.heatmap;
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
        
        function [maplabels,mapsWithContents,maps,index] = getMapOverview(obj)
            maplabels = {};
            maps = {};
            mapsWithContents = {};
            index = [];
            props = properties(obj);
            for p = 1:length(props)
                if contains(props{p},'map')
                    index(end+1) = false; %might become true in if-loop
                    maplabels{end+1} = props{p};
                  
                    sz = size(obj.(props{p}));
                    if prod(sz)==0
                        sz_string = '__________';
                    else
                        sz_string = '[1 volume]';
                          maps{end+1} = obj.(props{p});
                          index(end) = true;
                    end
                    mapsWithContents{end+1} = [sz_string,': ',props{p}];
                    
                end
            end
            index = logical(index);
        end
        
        function saveAllNiiToFolder(obj,outputdir)
            if nargin<2
                outputdir=obj.outputdir;
            end
            
            [outfolder,~]=fileparts(outputdir);
            
            outputfolder = fullfile(outfolder,['Heatmap__',obj.Tag]);
            mkdir(outputfolder)
            [maplabels,mapsWithContents,maps,index] = getMapOverview(obj);
            indx = find(index);
            for i = 1:numel(indx)
                iIndex = indx(i);
                maps{i}.savenii(fullfile(outputfolder,[maplabels{iIndex},'.nii']));
            end
            disp(['Saved to ',outputfolder])
            
        end
        
        %save function, to be called by heatmap_cook.. saves without
        %memory... save function to be added to to voxeldatastack and
        %LOOroutin 
%         function description = get.Description(obj)
%             if isempty(obj.Description)
%                 description= inputdlg('enter description:');
%                 obj.Description=description;
%             else
%                 description = obj.Description;
%             end
%         end
%         
%         function tag = get.Tag(obj)
%             if isempty(obj.Tag)
%                 tag = inputdlg('enter heatmap name:');
%                 obj.Tag = tag;
%             else
%                 tag = obj.Tag;
%             end
%         end
        
        function obj=save(obj,outputdir)
            if nargin<2
                outputdir=obj.outputdir;
            end
            
            [outfolder,~]=fileparts(outputdir);
            
            
            heatmap = obj;
            save(fullfile(outfolder,[obj.Tag,'.heatmap']),'heatmap','-v7.3');
            
            disp(['Heatmap was saved here: ',fullfile(outfolder,[obj.Tag,'.heatmap'])])
            disp('The heatmap is available as ''heatmap'' in your workspace.')
            assignin('base','heatmap',heatmap)
            
        end
    end
    
    
    
end


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
        
        function [maplabels,mapsWithContents,maps] = getMapOverview(obj)
            maplabels = {};
            maps = {};
            mapsWithContents = {};
            props = properties(obj);
            for p = 1:length(props)
                if contains(props{p},'map')
                    maplabels{end+1} = props{p};
                  
                    sz = size(obj.(props{p}));
                    if prod(sz)==0
                        sz_string = '__________';
                    else
                        sz_string = '[1 volume]';
                          maps{end+1} = obj.(props{p});
                    end
                    mapsWithContents{end+1} = [sz_string,': ',props{p}];
                end
            end
        end
        
        %save function, to be called by heatmap_cook.. saves without
        %memory... save function to be added to to voxeldatastack and
        %LOOroutin 
        function description = get.Description(obj)
            if isempty(obj.Description)
                description= inputdlg('enter description:');
                obj.Description=description;
            else
                description = obj.Description;
            end
        end
        
        function tag = get.Tag(obj)
            if isempty(obj.Tag)
                tag = inputdlg('enter heatmap name:');
                obj.Tag = tag;
            else
                tag = obj.Tag;
            end
        end
        
        function obj=save(obj,outputdir)
            if nargin<2
                outputdir=obj.outputdir;
            end
            
            [outfolder,~]=fileparts(outputdir);
            

            publicProperties = properties(obj); % convert from class heatmap to struct to be able to save without changing properties
            exportheatmap = struct();
            for iField = 1:numel(publicProperties)
                exportheatmap.(publicProperties{iField}) = obj.(publicProperties{iField});
            end

                
            save(fullfile(outfolder,[obj.Tag,'.heatmap']),'-struct','exportheatmap','-v7.3');
        end
    end
    
    
    
end


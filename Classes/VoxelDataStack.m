classdef VoxelDataStack < handle
    %VOXELDATASTACK Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Voxels %4D or sparse but always serialized
        R
        Weights
    end
    
    properties(Hidden)
        Recipe
        RecipePath
        LayerLabels
        ScoreLabel
        SparseOptimization = true;
    end
    
    methods
        function obj = VoxelDataStack(Voxels,R,Weights)
            if nargin>0
                %serialize
                if length(size(Voxels))>2
                    obj.Voxels = reshape(single(Voxels),[],size(Voxels,4)); %by default to minimize memory consumption
                else
                    obj.Voxels = single(Voxels);
                end
            end
            if nargin>1
                obj.R = R;
            end
            if nargin>2
                obj.Weights = Weights;
            end
            
        end
        
        function weights = get.Weights(obj)
            if isempty(obj.Weights)
                weights = ones(1,size(obj.Voxels,4));
            end
            weights = obj.Weights;
            
        end
        
        function l =length(obj)
            l = size(obj.Voxels,2);
        end
        
        function bool = issparse(obj)
            bool = issparse(obj.Voxels);
        end
        function bool = isfull(obj)
            bool = ~obj.issparse;
        end
        
        function obj = newEmpty(obj,reference,n_files)
            if nargin==1
                n_files = 1;
            end
            switch class(reference)
                case 'double'
                    %empty
                case 'imref3d'                    
                    obj.R = reference;
                otherwise
                    obj.R = reference.R;    
            end
            obj.Voxels = zeros([prod(obj.R.ImageSize),n_files]); %% change numeric class to int8 for memory optimisation, not valid for functional data
            obj.Weights = ones(1,n_files);
        end
        
        function array = get4DVoxels(obj)
            array = reshape(full(obj.Voxels),obj.R.ImageSize(1),obj.R.ImageSize(2),obj.R.ImageSize(3),[]);
        end
        
        function saveAs4Dnii(obj,filename)
            if nargin==2
                [outfolder,file,ext] = fileparts(filename);
                outfile = [file,'.nii'];
            else
                [outfile,outfolder] = uiputfile(fullfile(obj.RecipePath,'*.nii'));
            end
            
            [x,y,z] = obj.R.worldToIntrinsic(0,0,0);
            spacing = [obj.R.PixelExtentInWorldX,obj.R.PixelExtentInWorldY,obj.R.PixelExtentInWorldZ];
            origin = [x y z];
            datatype = 16;%64;
            nii = make_nii(double(permute(obj.get4DVoxels,[2 1 3 4])), spacing, origin, datatype);
            save_nii(nii,fullfile(outfolder,outfile));
            
            
            
        end
        
        function obj = construct(obj)
            
            answer = questdlg('how do you like to load the data?','select Data to load',...
                'from Recipe',...
                'directly from nii files',...
                'from Recipe');
            switch answer
                case 'from Recipe'
                    obj.loadStudyDataFromRecipe();
                case 'directly from nii files'
                    obj.loadDataFromFolder();
                otherwise
                    return %user aborted
            end
            
        end
        
        function obj = loadDataFromFolder(obj,folder)
            if nargin==1
                waitfor(msgbox('Find the folder with nii files'))
                [folder] = uigetdir('*.nii','Get the folder with nii files');
                if folder==0
                    return
                end
            end
            
            files = A_getfiles(fullfile(folder,'*.nii'));
            obj.RecipePath = folder;
            for iFile = 1:numel(files)
                if iFile==1
                    vd_template = VoxelData(fullfile(folder,files(iFile).name));
                    vd = vd_template;
                    obj.R = vd.R;
                else
                    vd = VoxelData(fullfile(folder,files(iFile).name)).warpto(vd_template);
                end
                obj.InsertVoxelDataAt(vd,iFile)
                
            end
            
        end
        
        function obj = loadStudyDataFromLegacyRecipe(obj,recipe,templatefile)
            if nargin==1
                waitfor(msgbox('Find the recipe'))
                [filename,foldername] = uigetfile('*.xlsx','Locate the recipe');
                if filename==0
                    return
                end
                if isempty(obj.R)
                   obj.R = VoxelDataStack.getTemplateSpace();
                end
            end
            
            if nargin==3
                obj.R = VoxelData(templatefile).R;
            end
            
            %load excel sheet with scores. Names should match the folders.
            obj.RecipePath=recipe;
            recipe = readtable(recipe);
            if isHeatmapMakerRecipe(recipe)
                obj = obj.loadStudyDataFromRecipe(recipe,templatefile);
                return
            end
            obj.Recipe = recipe;
            scoreTag = getScoreTag(recipe);
            scores = obj.Recipe.(scoreTag);
            
       
            
            
            %-- GRouping data before adding to the stack? build some logic
            %here if required.
            
            
            %set up Stack
            obj.newEmpty([],length(obj.Recipe.filelocation)); %ref is empty, becasue it's already set.
            obj.ScoreLabel = scoreTag;
            scene = getScene;
            
            for i = 1:height(obj.Recipe)
                
                
                %read out VTA settings:
                leadtype = obj.Recipe.leadtype{i};
                amplitude = obj.Recipe.amplitude(i);
                pulsewidth = obj.Recipe.pulsewidth(i);
                activevector = obj.Recipe.activecontact{i};
                groundedcontact = obj.Recipe.groundedcontact{i};
                voltagecontrolled = obj.Recipe.voltage{i};
                T = eval(obj.Recipe.Tlead2MNI{i});
                
                %make a VTA name
                vtaname = VTA.constructVTAname(leadtype,amplitude,pulsewidth,activevector,groundedcontact,voltagecontrolled);
                
                %create an electrode in MNI space, and generate the VTA.
                e = Electrode;
                e.transform(T); %move lead from default position to legacy MNI
                e.legacy2MNI; %move lead to MNI space.
                if ~e.isLeft()
                    e.mirror()
                end
                e.makeVTA(vtaname)
                e.VTA.Tag = [obj.Recipe.name{i},'_',obj.Recipe.leadname{i},'_',obj.Recipe.stimplanname{i}];
                e.VTA.Space = Space.MNI2009b;
                %                 a = e.see(scene);
                %                 a.changeSetting('cathode',cathode);
                if ~isempty(scene)
                    e.VTA.see(scene)
                end
                
                %warp to tempalte space;
                out = e.VTA.Volume.warpto(obj.R);
                obj.InsertVoxelDataAt(out,i);
                obj.Weights(i) = obj.Recipe.(obj.ScoreLabel)(i);
                obj.LayerLabels{i} = e.VTA.Tag;
                
            end
            
            
            
            
            
            %--- supporting functions
            function bool = isHeatmapMakerRecipe(recipe)
                bool = length(properties(recipe))<22; %should be 25 for legacy.. but the last columns are not required.
            end
            function scoreTag = getScoreTag(recipe)
                options= recipe.Properties.VariableNames(21:end);
                if length(options)==1
                    scoreTag = options{1};
                else
                    choice = listdlg('ListString',options,'PromptString','Select a label:');
                    scoreTag = options{choice};
                end
                
            end
        end
        
        function templateSpace(obj,templatespace)
            switch class(templatespace)
                case 'imref'
                    obj.R = templatespace;
                otherwise
                    obj.R = templatespace.R;
            end
        end
        
        
        
        function obj = loadStudyDataFromRecipe(obj,recipe,templatefile)
            if nargin==1
                waitfor(msgbox('Find the recipe'))
                [filename,foldername] = uigetfile('*.xlsx','Locate the recipe');
                if filename==0
                    return
                end
                recipe = fullfile(foldername,filename);
                
                if isempty(obj.R)
                   obj.R = VoxelDataStack.getTemplateSpace();
                end
            end
            
            if nargin==3
                obj.R = VoxelData(templatefile).R;
            end
            
            
            %load excel sheet with scores. Names should match the folders.
            obj.RecipePath=recipe;
            recipe = readtable(recipe);
            if isLegacyRecipe(recipe)
                obj = obj.loadStudyDataFromLegacyRecipe(obj.RecipePath);
                return
            end
            obj.Recipe = recipe;
            scoreTag = getScoreTag(recipe);
            scores = obj.Recipe.(scoreTag);
           
            
            %set up Stack
            obj.newEmpty([],length(obj.Recipe.fullpath)); %ref is empty because it is already set.
            obj.ScoreLabel = scoreTag;
            
            %subfolder or one folder?
            data_is_in_subfolders = any(ismember(recipe.Properties.VariableNames,'folderID'));
            answer = questdlg('You have organized your data in subfolders. How should the folders be interpreted? Are you dealing with bilateral therapy?',...
                'Arena',...
                'Yes, this is bilateral. Keep the files seperate in the sampling',...
                'They can be safely merged and treated as one file',...
                'Yes, this is bilateral. Keep the files seperate in the sampling');
            switch answer
                case 'Yes, this is bilateral. Keep the files seperate in the sampling'
                    individual_sampling = true;
                otherwise
                    individual_sampling = false;
            end
            
            
            %Loop over the folders. All files in a folder will be merged.
            [parentfolder,~] = fileparts(obj.Recipe.fullpath{1});
            if not(exist(parentfolder,'dir'))
                warndlg('The folder in the recipe does not exist. This can occur when the recipe was made on a different computer or if the files have been moved. This can be fixed by using add-ons > heatmapmaker > other > repair recipe.')
                return
            end
            subfolders.name = 1;
            for i = 1:height(obj.Recipe)
                
                if data_is_in_subfolders
                    files = A_getfiles(fullfile(obj.Recipe.fullpath{i},'*.nii'));
                    for iFile = 1:numel(files)
                        thisFile = fullfile(obj.Recipe.fullpath{i},files(iFile).name);
                        vd = VoxelData(thisFile);
                        if any(isnan(vd.Voxels(:)))
                            vd.Voxels(isnan(vd.Voxels)) = 0;
                        end
                        
                        %Mirror to the left.
                        cog = vd.getcog;
                        if cog.x>1 && obj.Recipe.Move_or_keep_left(i)
                            vd.mirror;
                        end
                        
                        %Add subfolders together
                        if iFile==1
                            together = vd.warpto(obj.R).makeBinary(0.5);
                        else
                            together = together+vd.warpto(obj.R).makeBinary(0.5);
                        end
                        
                    end
                    if not(individual_sampling)
                        together = together.makeBinary(0.5);
                    end
                    
                    obj.InsertVoxelDataAt(together,i);
                    id = obj.Recipe.folderID(i);
                else
                    vd = VoxelData(obj.Recipe.fullpath{i});
                    if any(isnan(vd.Voxels(:)))
                        vd.Voxels(isnan(vd.Voxels)) = 0;
                    end
                    
                    %Mirror to the left.
                    cog = vd.getcog;
                    if cog.x>1 && obj.Recipe.Move_or_keep_left(i)
                        vd.mirror;
                    end
                    obj.InsertVoxelDataAt(vd,i);
                    id = obj.Recipe.fileID(i);
                end
                
                %get the weight
                
                obj.Weights(i) = scores(i);
                obj.LayerLabels{i} = id;
            end
            
            
            function score_tag = getScoreTag(recipe)
                if length(recipe.Properties.VariableNames)==4
                    score_tag = recipe.Properties.VariableNames{4};
                else
                    indx = listdlg('Liststring',recipe.Properties.VariableNames(4:end));
                    score_tag = recipe.Properties.VariableNames{1+indx};
                end
            end
            
            function bool = isLegacyRecipe(recipe)
                bool = length(properties(recipe))>20 %should be 25.. but the last columns are not required.
                
            end
        end
        
        
        
        
        
        function obj = InsertVoxelDataAt(obj,vd,index)
            sizeStack = size(obj.Voxels);
            if obj.issparse
                 if ~length(obj.Voxels)==numel(vd.Voxels)
                     vd = vd.warpto(obj);
                 end
            else
                if ~any(sizeStack==0)
                    if any(not(numel(vd.Voxels)==max(sizeStack)))
                        vd = vd.warpto(obj);
                    end
                end
            end
            
            % sparse / full decision tree
            if issparse(obj)
                obj.insertSparse(vd.Voxels,index)
            elseif nnz(vd.Voxels)/numel(vd.Voxels) < 0.5 && obj.SparseOptimization
                answer  = questdlg('It looks like your data consists of fibers or VTAs. Memory optimization can be applied. Do you want that?','Arena','yes, optimize','no','yes, optimize');
                switch answer 
                    case 'yes, optimize'
                         obj.insertSparse(vd.Voxels,index)
                    otherwise
                        obj.insertFull(vd.Voxels,index)
                        obj.SparseOptimization = false;
                end
            else
                obj.insertFull(vd.Voxels,index)
            end
                        
        end
        
        function obj = insertFull(obj,v,i)
            obj.Voxels(:,i) = v(:);
        end
        
        function obj = insertSparse(obj,v,i)
            if ~obj.issparse
                disp('applying memory saving on data storage...')
                obj.sparse();
            end
            obj.Voxels(:,i) = sparse(double(v(:)));
        end
        
        
        function vd = sum(obj)
            vd = VoxelData(sum(obj.Voxels,4),obj.R);
        end
        
        function binaryObj = makeBinary(obj,T)
            if nargin==1
                
                %ask for user input
                histf = figure;histogram(obj.Voxels(:),50);
                set(gca, 'YScale', 'log')
                try
                    [T,~] = ginput(1);
                catch
                    error('user canceled')
                end
                close(histf)
                
            end
            
            if nargout==1
                binaryObj = VoxelDataStack;
                binaryObj(obj.Voxels>T,obj.R,obj.Weights);
            else
                obj.Voxels = obj.Voxels>T;
            end
            
        end
        
        function vd = getVoxelDataAtPosition(obj,index)
            voxels = obj.Voxels(:,index);
            Voxels3D = obj.reshape(voxels);
            vd = VoxelData(Voxels3D,obj.R);
        end
        
        function heatmap = convertToLOOHeatmap(obj,iLOO,requiredMaps)
            
            
            Vloo = obj.Voxels;
            Vloo(:,iLOO) = [];
            Wloo = obj.Weights;
            Wloo(iLOO) = [];
            Rloo = obj.R;
            LOOstack = VoxelDataStack(Vloo,Rloo,Wloo);
            
            
            heatmap = Heatmap;
            heatmap.fromVoxelDataStack(LOOstack,'notitle','nodescription', requiredMaps);
            
            
            
        end
        
        
        
        
        function HeatmapVDS = convertToLOOHeatmaps(obj,filename,description,startingFrom)
            if nargin<4
                startingFrom = 1;
            end
            
            saveFileWhenDone = 1;
            if nargin==1
                saveFileWhenDone = 0;
                filename = '';
                description = '';
            end
            
            size_of_maps = [size(obj.Voxels),numel(obj.Weights)];
            
            HeatmapVDS.Signedpmap = VoxelDataStack;
            HeatmapVDS.Signedpmap.setSize(size_of_maps,'int8');
            HeatmapVDS.Tmap = VoxelDataStack;
            HeatmapVDS.Tmap.setSize(size_of_maps,'int8');
            
            for iLOO = startingFrom:numel(obj.Weights)
                Vloo = obj.Voxels;
                Vloo(:,iLOO) = [];
                Wloo = obj.Weights;
                Wloo(iLOO) = [];
                Rloo = obj.R;
                LOOstack = VoxelDataStack(Vloo,Rloo,Wloo);
                try
                    [parent,sub,fn] = fileparts(obj.LayerLabels{iLOO});
                catch
                    sub=obj.LayerLabels{iLOO};
                end
                output = LOOstack.convertToHeatmap(sub,description,'false',filename);
                if iLOO ==1
                    HeatmapVDS.Signedpmap.R = Rloo;
                    HeatmapVDS.Tmap.R = Rloo;
                end
                output.Signedpmap.Voxels = int8(output.Signedpmap.Voxels*100);
                output.Tmap.Voxels = int8(output.Tmap.Voxels*100);
                HeatmapVDS.Signedpmap.InsertVoxelDataAt(output.Signedpmap,iLOO);
                HeatmapVDS.Tmap.InsertVoxelDataAt(output.Tmap,iLOO);
                
                clear LOOstack
            end
            
        end
        
        
        function obj =  setSize(obj,sz,classtype)
            if ~isempty(obj.Voxels)
                warning('Instance already contains data. Allocation request is ignored')
                return
            end
            
            if nargin==3
                obj.Voxels = zeros(sz(1:4),classtype);
            else
                obj.Voxels = NaN(sz(1:4));
            end
            
            obj.Weights = NaN([1,sz(4)]);
            
        end
        
        
        function heatmap = convertToHeatmapBasedOnVoxelValues(obj,filename,description)
            global arena
            if not(isfield(arena.Settings,'rootdir'))
                error('Your settings file is outdated. Please remove config.mat and restart MATLAB for a new setup')
            end
            
            if nargin<3
                error('Include the heatmapname and a short description!')
            end
            
            raw.recipe = [];
            raw.files = obj.LayerLabels;
            [tmap,pmap,signedpmap] = obj.ttest();
            heatmap = Heatmap();
            heatmap.Tmap = tmap;
            heatmap.Pmap = pmap;
            heatmap.Signedpmap = signedpmap;
            heatmap.Raw = raw;
            heatmap.Description = description;
            heatmap.Amap = VoxelData(nanmean(obj.Voxels,4),heatmap.Tmap.R);
            
            
            
        end
        
        
        function heatmap = convertToHeatmap(obj,filename)
            
            filename= inputdlg('enter description:');
            
            heatmap = Heatmap;
            heatmap.fromVoxelDataStack(obj,filename{:})
        end
        
        
        

        
        function [tmap,pmap,signedpmap] = ttest(obj)
            
            if ~obj.issparse
                serialized = reshape(obj.Voxels,[],size(obj.Voxels,4));
            else
                serialized = obj.Voxels;
            end
            
            [~,p_voxels,~,stat] = ttest(serialized');
            t_voxels = stat.tstat;
            
            stacksize = size(obj.Voxels);
            outputsize = stacksize(1:3);
            signed_p_voxels = (1-p_voxels).*sign(t_voxels);
            tmap = VoxelData(reshape(t_voxels,outputsize),obj.R);
            pmap = VoxelData(reshape(p_voxels,outputsize),obj.R);
            signedpmap = VoxelData(reshape(signed_p_voxels,outputsize),obj.R);
            Done;
        end
        
        function v = reshape(obj,v)
            if issparse(v)
                v = full(v);
            end
            v = reshape(v,obj.R.ImageSize(1),obj.R.ImageSize(2),obj.R.ImageSize(3),[]);
        end
        
        function nmap = count(obj)
            v = obj.Voxels;
            v = v>0.5; %%% convert to double class deleted
            if obj.issparse
                nmap_vector = full(sum(v,2));
            else
                nmap_vector = sum(v,2);
            end
            
            nmap = VoxelData(obj.reshape(nmap_vector),obj.R);
            
        end
            
        
        function [tmap,pmap,signedpmap] = ttest2(obj)
            
            if all(obj.Weights==0)
                error('All weights are set to 0. This will not work.')
            end
            

            serialized = obj.Voxels;
            t_voxels = zeros([length(serialized),1]);
            p_voxels = zeros([length(serialized),1]);
            disp(' ~running ttest2')
            for i =  1:length(serialized)
                
                if ~nnz(serialized(i,:)>0.5) || all(serialized(i,:)) % checks if the voxel is all zeros or all ones across all subjects
                    p = 1;
                    t = 0;
                else
                    [~,p,~,stat] = ttest2(obj.Weights(serialized(i,:)>0.5),obj.Weights(not(serialized(i,:)>0.5)));
                    t = stat.tstat;
                end
                t_voxels(i) = t;
                p_voxels(i) = p;
                
                if isnan(t)
                    keyboard
                end
                
            end
            
            outputsize = obj.R.ImageSize;
            signed_p_voxels = (1-p_voxels).*sign(t_voxels);
            tmap = VoxelData(reshape(t_voxels,outputsize),obj.R);
            pmap = VoxelData(reshape(p_voxels,outputsize),obj.R);
            signedpmap = VoxelData(reshape(signed_p_voxels,outputsize),obj.R);
        end
        
        function obj = full(obj)
            if obj.issparse
                v = full(obj.Voxels);
                obj.Voxels = reshape(v,obj.R.ImageSize(1),obj.R.ImageSize(2),obj.R.ImageSize(3),[]);
            end
        end
        
        function obj = sparse(obj)
            if ~obj.issparse
                serialized = reshape(obj.Voxels,prod(obj.R.ImageSize),[]);
                obj.Voxels = sparse(double(serialized));
            end
        end
        
        
        function [tmap,pmap,signedpmap] = ttest_fuckedup(obj)
            %Explanation
            %-----
            %1. Serialization
            % First the 4D array is converted to 2D. So that every voxel is
            % on a row, and the columns are filled with 1 or 0 depending if
            % it belongs to this instance or not.
            
            %2. Pointer
            % Instead of repeating the same calculations over and over, I
            % give an ID to similar voxels. This I call a pointer in this
            % context. The pointer is a decimal number based on the binary
            % combination of the voxel values. If voxel 1 contains:
            % [0 0 1 1] then this translates to value 3. Hence all voxels
            % with this pattern will now be referred to as 3.
            
            %3. T-test
            %te test is not done for every voxel. Instead it's done for
            %every unique ID. For each existing voxelcombination the ttest
            %is performed. (testing data inside voxel against data not in
            %voxel in a two sample ttest). Then these values are applied to
            %similar voxels
            
            if length(obj.Weights)<=5
                error('Insufficient data for stats')
            end
            disp('serialize')
            serialized = reshape(obj.Voxels,[],size(obj.Voxels,4));
            serialized_pointer = convertBinaryToDecimal(serialized);
            t_voxels = zeros([length(serialized),1]);
            p_voxels = zeros([length(serialized),1]);
            
            uniquePointers = unique(serialized_pointer);
            for iPointer = 1:length(uniquePointers)
                
                thisPointer = uniquePointers(iPointer);
                disp(['Pointer: ',num2str(thisPointer)])
                original = convertDecimalToBinary(thisPointer,length(obj.Weights));
                
                if any([all(original),all(not(original))])
                    p = 1;
                    t = 0;
                else
                    [~,p,~,stat] = ttest2(obj.Weights(original),obj.Weights(not(original)));
                    t = stat.tstat;
                end
                t_voxels(serialized_pointer==thisPointer) = t;
                p_voxels(serialized_pointer==thisPointer) = p;
                
            end
            
            stacksize = size(obj.Voxels);
            outputsize = stacksize(1:3);
            signed_p_voxels = 1-p_voxels.*sign(t_voxels);
            tmap = VoxelData(reshape(t_voxels,outputsize),obj.R);
            pmap = VoxelData(reshape(p_voxels,outputsize),obj.R);
            signedpmap = VoxelData(reshape(signed_p_voxels,outputsize),obj.R);
            
            
            function out = convertDecimalToBinary(in,L)
                out = dec2bin(in)=='1';
                while length(out)<L
                    out(end+1) = 0; %extend so the length matches the number of weights
                end
            end
            function out = convertBinaryToDecimal(a)
                home;
                disp('Converting to Decimal Pointers')
                binarylist = 2.^(0:size(a,2)-1);
                
                out = zeros([length(a),1],'int8');
                index = 1;
                stepsize = 10000000;
                allOK = true;
                while allOK
                    disp('*snip in pieces of 10 million voxels*')
                    endindex = min([stepsize,length(a)-index]);
                    out(index:index+endindex) = int8(single(a(index:index+endindex,:))*binarylist');
                    
                    index = index+stepsize;
                    if index > length(a)
                        allOK = false;
                    end
                    
                    
                end
                
            end
            
        end
        function copyObj = copy(obj)
            copyObj = VoxelDataStack;
            copyObj.Voxels = obj.Voxels;
            copyObj.R = obj.R;
            copyObj.Weights = obj.Weights;
            copyObj.Recipe = obj.Recipe;
            copyObj.RecipePath = obj.RecipePath;
            copyObj.LayerLabels = obj.LayerLabels;
            copyObj.ScoreLabel = obj.ScoreLabel;
        end
        
    end
    
    methods (Static)
        function R = getTemplateSpace()
            [selection,ok] = listdlg('PromptString','Select a template space:',...
                'SelectionMode','single',...
                'ListString',{'Basal ganglia (0.25mm) - 34mb ',...
                'MNI 2009b (0.5mm) - 138mb',...
                '[based on file]'},...
                'ListSize',[250,100]);
            
            global arena
            root = arena.getrootdir;
            templatefolder = fullfile(root,'Elements','Imrefs');
            
            
            if ok
                switch selection
                    case 1
                        load(fullfile(templatefolder,'BasalGanglia.mat'),'R')
                    case 2
                        load(fullfile(templatefolder,'MNI2009b.mat'),'R')
                    case 3
                        VD = VoxelData;
                        VD.loadnii();
                        R = VD.R;
                        
                end
            else
                templateSpace = [];
            end
            
            
        end
        
        
    end
    
end



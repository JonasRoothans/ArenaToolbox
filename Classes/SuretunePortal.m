classdef SuretunePortal
    %SURETUNEPORTAL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        handles
        session
        scene
    end
    
    methods
        function obj = SuretunePortal(scene,dcmfile)
            
            obj.scene = scene;

            
            %load session
            if nargin==2
                obj = obj.openSession(dcmfile);
            elseif nargin==1
                obj = obj.openSession;
            end
            
            
            %construct figure
            obj = obj.constructFigure(dcmfile);
            
           
            
            
            
        end
        
        function obj = openSession(obj,dcmpath)
            if nargin==2
                S = Session;
                S.loadsession(dcmpath)
            else
                S = Session;
                S.loadsession;
            end
            
            obj.session = S;
        end
        
        
        function obj = constructFigure(obj,dcmfile)
            S = obj.session;
            
            [name,type] = S.listregisterables;
            n = numel(type);
            ITEM_SPACE = 30;
            ITEM_LEFTMARGIN = 20;
            ITEM_WIDTH = 200;
            ITEM_HEIGHT = 30;
            windowheight = ITEM_SPACE*(n+1);
            
            obj.handles.f =  figure('outerposition',[300 300 250 windowheight+10],...
                'menubar','none',...
                'name',['Arena: ',obj.scene.Title,' - ',obj.session.patient.name],...
                'numbertitle','off',...
                'resize','off',...
                'CloseRequestFcn',@closePortal);
            
            buttons = [];
            for iRegisterable = 1:n
                bottom = windowheight-(iRegisterable+0.5)*ITEM_SPACE;
                thisType = type{iRegisterable};
                switch thisType
                    case 'Dataset'
                        thisR = S.getregisterable(name{iRegisterable});
                        string = ['Dataset: ',thisR.label];
                        callback = @cb_dataset;
                        userdata = {thisR,dcmfile};
                        buttons(iRegisterable) = uicontrol('style','togglebutton','Position',[ITEM_LEFTMARGIN,bottom,ITEM_WIDTH,ITEM_HEIGHT],...
                            'String',string,...
                            'UserData',userdata,...
                            'callback',callback) ;
                    case 'ACPCIH'
                        thisR = S.getregisterable(name{iRegisterable});
                        string = 'AC PC Coorinate system';
                        callback = @cb_ACPC;
                        userdata = {thisR,dcmfile};
                        buttons(iRegisterable) = uicontrol('style','togglebutton','Position',[ITEM_LEFTMARGIN,bottom,ITEM_WIDTH,ITEM_HEIGHT],...
                            'String',string,...
                            'UserData',userdata,...
                            'callback',callback) ;
                    case 'Lead'
                        thisR = S.getregisterable(name{iRegisterable});
                        string = [thisR.leadType,': ',thisR.label,];
                        callback = @cb_lead;
                        userdata = {thisR,dcmfile};
                        buttons(iRegisterable) = uicontrol('style','togglebutton','Position',[ITEM_LEFTMARGIN,bottom,ITEM_WIDTH,ITEM_HEIGHT],...
                            'String',string,...
                            'UserData',userdata,...
                            'callback',callback) ;
                    case 'Atlas'
                        thisR = S.getregisterable(name{iRegisterable});
                        string = ['Atlas: ',thisR.group,' ',thisR.hemisphere];
                        callback = @cb_atlas;
                        userdata = {thisR,dcmfile};
                        buttons(iRegisterable) = uicontrol('style','togglebutton','Position',[ITEM_LEFTMARGIN,bottom,ITEM_WIDTH,ITEM_HEIGHT],...
                            'String',string,...
                            'UserData',userdata,...
                            'callback',callback) ;
                    case 'ImageBasedStructureSegmentation'
                        thisR = S.getregisterable(name{iRegisterable});
                        string = ['Segmentation: ',thisR.label];
                        callback = @cb_ibs;
                        userdata = {thisR,dcmfile};
                        buttons(iRegisterable) = uicontrol('style','togglebutton','Position',[ITEM_LEFTMARGIN,bottom,ITEM_WIDTH,ITEM_HEIGHT],...
                            'String',string,...
                            'UserData',userdata,...
                            'callback',callback) ;
                    case 'ManualStructureSegmentation'
                        thisR = S.getregisterable(name{iRegisterable});
                        string = ['Manual Segmentation: ',thisR.label];
                        callback = @cb_mss;
                        userdata = {thisR,dcmfile};
                        buttons(iRegisterable) = uicontrol('style','togglebutton','Position',[ITEM_LEFTMARGIN,bottom,ITEM_WIDTH,ITEM_HEIGHT],...
                            'String',string,...
                            'UserData',userdata,...
                            'callback',callback) ;
                        
                    otherwise
                        thisR = S.getregisterable(name{iRegisterable});
                        string = [class(thisR),': ',thisR.label];
                        buttons(iRegisterable) = uicontrol('style','togglebutton','Position',[ITEM_LEFTMARGIN,bottom,ITEM_WIDTH,ITEM_HEIGHT],...
                            'String',string,...
                            'Enable','off') ;
                end
            end %end-- loop to generate the GUI
            
            obj.handles.buttons = buttons;

            
            
            %% callbacks
            function closePortal(src,callbackdata)
                try
                obj.scene.handles.menu.stusessions
                
                %find menu item pointing to this window in the scene
                index = [];
                for iSession = 1:numel(obj.scene.handles.menu.stusessions.openwindows)
                    if obj.scene.handles.menu.stusessions.openwindows{iSession}.UserData.session == obj.session;
                        index = iSession;
                    end
                end
                if isempty(index)
                    warning('something is messed up with the suretuneportals')
                end
                
                %delete from ui and list
                delete(obj.scene.handles.menu.stusessions.openwindows{index})
                obj.scene.handles.menu.stusessions.openwindows(index) = [];
                if isempty(obj.scene.handles.menu.stusessions.openwindows)
                    obj.scene.handles.menu.stusessions.main.Visible = 'off';
                end
                catch
                    warning('something is messed up with the suretuneportals')
                    delete(obj.handles.f)
                end
                delete(obj.handles.f)
            end
            
            function cb_dataset(hObject,b)
                this = hObject.UserData{1};
                
                [T,reglinkdescription] = universalCallbackRoutine(this);
                
                %create VoxelData and warp
                vd = VoxelData();
                vd.importSuretuneDataset(this);
                vd.imwarp(T);
                
                %see
                if not(isempty(obj.scene))
                    answer = questdlg('Import as mesh or slice?','Almost ready..','mesh','slice','mesh');
                    switch answer
                        case 'mesh'
                            actor = vd.getmesh.see(obj.scene);
                        case 'slice'
                            actor = vd.getslice.see(obj.scene);
                            %                     s = Slicei;
                            %                     s.getFromVoxelData(vd);
                            %                     actor = s.see(obj.scene);
                            %actor = vd.getslice.see(obj.scene);
                    end
                    actor.changeName([hObject.String,' via ',reglinkdescription])
                end
                actor.PathDirectory=hObject.UserData{2};
            end
            
            function cb_mss(hObject,h)
                this = hObject.UserData{1};
                [T,reglinkdescription] = universalCallbackRoutine(this);
                m = this.computemesh;
                %[V,F] = SDK_smoothedges(m,10,100,8,0.7)
                % maxMaxEdgeLength,maxVertices,maxConnections,buldgeFactor)
                %         [V,F] = SDK_simultaneoussubdividesurface(m,2,100,10,0.5);
                [V,F] = A_subdividesurface(m,0,200,10,0.5);
                
                segmentation = ObjFile(F,V);
                segmentation.transform(T).see(obj.scene)
                
            end
            
            function cb_ibs(hObject,h)
                this = hObject.UserData{1};
                [T,reglinkdescription] = universalCallbackRoutine(this);
                
                %create VoxelData and warp
                vd = VoxelData();
                vd.importSuretuneDataset(this.parent);
                
                %crop vd to boundingbox
                leftDown = Vector3D(this.boundingBox.leftDown);%.transform(T);
                rightUp = Vector3D(this.boundingBox.rightUp);%.transform(T);
                vd = vd.crop(leftDown,rightUp);
                vd.padcropped(this.thresholdType)
                vd = vd.imwarp(T);
                
                
                if strcmp(this.blurEnabled,'True')
                    vd.smooth;
                end
                
                %get threshold
                rescaleIntercept = str2num(this.parent.volume.volumeInfo.rescaleIntercept);
                rescaleSlope = str2num(this.parent.volume.volumeInfo.rescaleSlope);
                
                T = (str2num(this.threshold)-rescaleIntercept) / rescaleSlope;
                
                %visualise
                actor =vd.getmesh(T).see(obj.scene);
                actor.changeSetting('complexity',100,'colorFace',SDK_hex2rgb(this.color(end-5:end))/255,'colorEdge',SDK_hex2rgb(this.color(end-5:end))/255);
                
                actor.changeName(this.label)
                actor.PathDirectory=hObject.UserData{2};
                
                
                
            end
            
            
            function cb_ACPC(hObject,b)
                this = hObject.UserData{1};
                [T,reglinkdescription] = universalCallbackRoutine(this);
                
                %create VectorCloud and warp
                AC = -1*Vector3D(this.ac-this.pc).norm/2;
                base = SDK_transform3d([0 AC 0;0 AC 0;0 AC 0],T);
                tips = SDK_transform3d([-1 AC 0; 0 AC-1 0; 0 AC 1],T);
                directions = tips-base;
                vc = VectorCloud(base,directions);
                
                %see
                if not(isempty(obj.scene))
                    actor = vc.see(obj.scene);
                    actor.changeName([hObject.String,' via ',reglinkdescription])
                end
                actor.PathDirectory=hObject.UserData{2};
            end
            
            
            function cb_lead(hObject,b)
                this = hObject.UserData{1};
                [T,reglinkdescription] = universalCallbackRoutine(this);
                
                %generate Electrode
                e = Electrode;
                c0 = SDK_transform3d([0 0 0],T);
                c3 = SDK_transform3d([0 0 6],T);
                
                
                e.Direction = Vector3D(c3-c0).unit.getArray';
                e.C0 = c0;
                e.Type = this.leadType;
                
                if numel(this.stimPlan)==0
                    if not(isempty(obj.scene))
                        actor = e.see(obj.scene);
                        actor.changeName(this.label)
                    end
                    actor.PathDirectory=hObject.UserData{2};
                else
                    for iStimplan = 1:numel(this.stimPlan)
                        %import VTA
                        vd = VoxelData();
                        vd.importSuretuneDataset(this.stimPlan{iStimplan}.vta.Medium);
                        vd.imwarp(T);
                        
                        if not(isempty(obj.scene))
                            actor = e.see(obj.scene);
                            actor.changeName([this.label,' ',this.stimPlan{iStimplan}.label])
                            
                            actor_vta = vd.getmesh(0.5).see(obj.scene);
                            actor_vta.changeName(['[VTA] ',this.label,' ',this.stimPlan{iStimplan}.label])
                        end
                        
                        actor.changeSetting('cathode',str2num(this.stimPlan{iStimplan}.activeRings),'anode', str2num(this.stimPlan{iStimplan}.contactsGrounded));
                        
                        
                        actor_vta.changeSetting('colorFace',[1 0.5 0])
                        actor.PathDirectory=hObject.UserData{2};
                        actor.Data.NumberOfLead=iStimplan;
                    end
                end 
            end
            function cb_atlas(hObject,b)
                this = hObject.UserData{1};
                [T,reglinkdescription] = universalCallbackRoutine(this);
                
                %load atlases
                rootdir = fileparts(fileparts(mfilename('fullpath')))
                legacypath = fullfile(rootdir,'Elements','SureTune');
                
                switch this.group
                    case 'Stn'
                        stn = ObjFile(fullfile(legacypath,'LH_STN-ON-pmMR.obj'));
                        rn = ObjFile(fullfile(legacypath,'LH_RU-ON-pmMR.obj'));
                        sn = ObjFile(fullfile(legacypath,'LH_SN-ON-pmMR.obj'));
                        
                        stn = stn.transform(T);
                        rn = rn.transform(T);
                        sn = sn.transform(T);
                        
                        if not(isempty(obj.scene))
                            actorstn = stn.see(obj.scene);
                            actorrn = rn.see(obj.scene);
                            actorsn = sn.see(obj.scene);
                            
                            actorstn.PathDirectory=hObject.UserData{2};
                            actorrn.PathDirectory=hObject.UserData{2};
                            actorsn.PathDirectory=hObject.UserData{2};
                            
                            actorstn.changeName(['STN via ',reglinkdescription])
                            actorsn.changeName(['SN via ',reglinkdescription])
                            actorrn.changeName(['RN via ',reglinkdescription])
                            
                            actorstn.changeSetting('colorFace',[0 1 0],'faceOpacity',20,'edgeOpacity',50,'complexity',50)
                            actorsn.changeSetting('colorFace',[1 1 0],'faceOpacity',20,'edgeOpacity',50,'complexity',50)
                            actorrn.changeSetting('colorFace',[1 0 0],'faceOpacity',20,'edgeOpacity',50,'complexity',50)
                        end
                        
                    case 'Gpi'
                        gpi = ObjFile(fullfile(legacypath,'LH_IGP-ON-pmMR.obj'));
                        gpe = ObjFile(fullfile(legacypath,'LH_EGP-ON-pmMR.obj'));
                        
                        gpi= gpi.transform(T);
                        gpe = gpe.transform(T);
                        if not(isempty(obj.scene))
                            actorgpi = gpi.see(obj.scene);
                            actorgpe = gpe.see(obj.scene);
                            
                            actorgpi.PathDirectory=hObject.UserData{2};
                            actorgpe.PathDirectory=hObject.UserData{2};
                            
                            actorgpi.changeName(['GPi via ',reglinkdescription])
                            actorgpe.changeName(['GPe via ',reglinkdescription])
                            actorgpi.changeSetting('colorFace',[0 0 1],'faceOpacity',20,'edgeOpacity',50,'complexity',50)
                            actorgpe.changeSetting('colorFace',[0 1 1],'faceOpacity',20,'edgeOpacity',50,'complexity',50)
                            
                        end
                        
                        
                end
                
                
            end
            
            
            %% Engine
            
            function [names,regs] = getRegistrationlink(suretuneRegisterable)
                session = suretuneRegisterable.session;
                [~,types] = session.listregisterables;
                atlas_indices = find(contains(types,'Atlas'));
                names = {};
                regs = {};
                
                for i = 1:numel(atlas_indices)
                    thisAtlas = session.getregisterable(atlas_indices(i));
                    names{i} = ['to MNI via ',thisAtlas.group,' ',thisAtlas.hemisphere];
                    regs{i} = thisAtlas;
                end
                names = [{'--','Native / Scanner','Suretune patient space','to MNI via ACPC'},names];
                regs = [{nan,suretuneRegisterable,session.getregisterable(1),session.getregisterable('acpcCoordinateSystem')},regs];
            end
            
            function Tfromreglink = getSecondTransformation(reglink)
                switch class(reglink)
                    case 'Atlas'
                        T = load('Tapproved.mat');
                        atlasname = [lower(reglink.hemisphere),lower(reglink.group),'2mni'];
                        Tatlas2fake = T.(atlasname);
                        Tfake2mni = [-1 0 0 0;0 -1 0 0;0 0 1 0;0 -37.5 0 1];
                        Tfromreglink = Tatlas2fake*Tfake2mni;
                    case 'ACPCIH'
                        Tlps2ras = diag([-1 -1 1 1]);
                        MCP2AC = Vector3D(reglink.ac-reglink.pc).norm*-0.5;
                        Tmcp2ac = [1 0 0 0;0 1 0 0;0 0 1 0;0 MCP2AC 0 1];
                        Tfromreglink = Tlps2ras*Tmcp2ac;
                    case 'Dataset'
                        Tfromreglink= diag([-1 -1 1 1]); %lps2ras
                    case 'ImageBasedStructureSegmentation'
                        Tfromreglink= diag([-1 -1 1 1]); %lps2ras
                    case 'ManualStructureSegmentation'
                        Tfromreglink= diag([-1 -1 1 1]); %lps2ras
                        
                    otherwise
                        keyboard
                end
                
            end
            
            function [T,description] = universalCallbackRoutine(this)
                [names,regs] = getRegistrationlink(this);
                [selection] = listdlg('PromptString','In which space do you want it?','ListString',names);
                
                %possibly abort?
                if isempty(selection);return;end
                if selection==1;return;end
                
                %first Transformation (registerable to reglink)
                reglink = regs{selection};
                Ttoreglink = this.session.gettransformfromto(this,reglink);
                
                %Second Transformation (reglink to arena)
                Tfromreglink = getSecondTransformation(reglink);
                
                T = round(Ttoreglink*Tfromreglink,6);
                description = names{selection};
            end
            
            
            
        end
    end
end


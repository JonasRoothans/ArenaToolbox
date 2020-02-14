function [output] = A_loadsuretune(OPTIONALscene)
%A_LOADSURETUNE Summary of this function goes here
%   Detailed explanation goes here
if nargin==1
    scene = OPTIONALscene;
else
    scene = [];
end

S = Session;
S.loadsession;
[name,type] = S.listregisterables;
n = numel(type);
ITEM_SPACE = 30;
ITEM_LEFTMARGIN = 20;
ITEM_WIDTH = 200;
ITEM_HEIGHT = 30;
windowheight = ITEM_SPACE*(n+1);

f =  figure('outerposition',[300 300 250 windowheight+10],...
    'menubar','none',...
    'name','Arena: Suretune loader',...
    'numbertitle','off',...
    'resize','off');

buttons = [];
for iRegisterable = 1:n
    bottom = windowheight-(iRegisterable+0.5)*ITEM_SPACE;
    thisType = type{iRegisterable};
    switch thisType
        case 'Dataset'
            thisR = S.getregisterable(name{iRegisterable});
            string = ['Dataset: ',thisR.label];
            callback = @cb_dataset;
            userdata = thisR;
            buttons(iRegisterable) = uicontrol('style','togglebutton','Position',[ITEM_LEFTMARGIN,bottom,ITEM_WIDTH,ITEM_HEIGHT],...
                'String',string,...
                'UserData',userdata,...
                'callback',callback) ;
        case 'ACPCIH'
            thisR = S.getregisterable(name{iRegisterable});
            string = ['AC PC Coorinate system'];
            callback = @cb_ACPC;
            userdata = thisR;
            buttons(iRegisterable) = uicontrol('style','togglebutton','Position',[ITEM_LEFTMARGIN,bottom,ITEM_WIDTH,ITEM_HEIGHT],...
                'String',string,...
                'UserData',userdata,...
                'callback',callback) ;
        case 'Lead'
            thisR = S.getregisterable(name{iRegisterable});
            string = [thisR.leadType,': ',thisR.label,];
            callback = @cb_lead;
            userdata = thisR;
            buttons(iRegisterable) = uicontrol('style','togglebutton','Position',[ITEM_LEFTMARGIN,bottom,ITEM_WIDTH,ITEM_HEIGHT],...
                'String',string,...
                'UserData',userdata,...
                'callback',callback) ;
        case 'Atlas'
            thisR = S.getregisterable(name{iRegisterable});
            string = ['Atlas: ',thisR.group,' ',thisR.hemisphere];
            callback = @cb_atlas;
            userdata = thisR;
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
output = {};


%% callbacks
    function cb_dataset(hObject,b)
        this = hObject.UserData;
        
        [T,reglinkdescription] = universalCallbackRoutine(this);
        
        %create VoxelData and warp
        vd = VoxelData();
        vd.importSuretuneDataset(this);
        vd.imwarp(T);
        
        %see
        if not(isempty(scene))
            answer = questdlg('Import as mesh or slice?','Almost ready..','mesh','slice','mesh');
            switch answer
                case 'mesh'
                    actor = vd.getmesh.see(scene);
                case 'slice'
                    actor = vd.getslice.see(scene);
            end
            actor.changeName([hObject.String,' via ',reglinkdescription])
        end
        
    end
    function cb_ACPC(hObject,b)
        this = hObject.UserData;
        [T,reglinkdescription] = universalCallbackRoutine(this);
        
        %create VectorCloud and warp
        AC = -1*Vector3D(this.ac-this.pc).norm/2;
        base = SDK_transform3d([0 AC 0;0 AC 0;0 AC 0],T);
        tips = SDK_transform3d([-1 AC 0; 0 AC-1 0; 0 AC 1],T);
        directions = tips-base;
        vc = VectorCloud(base,directions);
        
        %see
        if not(isempty(scene))
            actor = vc.see(scene);
            actor.changeName([hObject.String,' via ',reglinkdescription])
        end
    end


    function cb_lead(hObject,b)
        this = hObject.UserData;
        [T,reglinkdescription] = universalCallbackRoutine(this);
        
        %generate Electrode
        e = Electrode;
        c0 = SDK_transform3d([0 0 0],T);
        c3 = SDK_transform3d([0 0 6],T);
        
        
        e.Direction = Vector3D(c3-c0).unit.getArray';
        e.C0 = c0;
        
        if numel(this.stimPlan)==0
            if not(isempty(scene))
                actor = e.see(scene);
                actor.changeName(this.label)
            end
        else
            for iStimplan = 1:numel(this.stimPlan)
                %import VTA
                vd = VoxelData();
                vd.importSuretuneDataset(this.stimPlan{iStimplan}.vta.Medium);
                vd.imwarp(T);
                
                if not(isempty(scene))
                    actor = e.see(scene);
                    actor.changeName([this.label,' ',this.stimPlan{iStimplan}.label])
                    
                    actor_vta = vd.getmesh(0.5).see(scene);
                    actor_vta.changeName(['[VTA] ',this.label,' ',this.stimPlan{iStimplan}.label])
                end
                
                actor.changeSetting('cathode',str2num(this.stimPlan{iStimplan}.activeRings));
                actor.changeSetting('anode', str2num(this.stimPlan{iStimplan}.contactsGrounded))
                
                if ~strcmp(this.leadType,'Medtronic3389')
                    actor.changeSetting('colorBase', [255,182,193]/255)
                end
                actor_vta.changeSetting('colorFace',[1 0.5 0])
            end
        end
    end
    function cb_atlas(hObject,b)
        this = hObject.UserData;
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
                
                if not(isempty(scene))
                    actorstn = stn.see(scene);
                    actorrn = rn.see(scene);
                    actorsn = sn.see(scene);
                    
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
                
                gpi= pi.transform(T);
                gpe = gpe.transform(T);
                if not(isempty(scene))
                    actorgpi = gpi.see(scene);
                    actorgpe = gpe.see(scene);
                    actorgpi.changeName(['GPi via ',reglinkdescription])
                    actorgpe.changeName(['GPe via ',reglinkdescription])
                    actorgpi.changeSetting('colorFace',[0 0 1],'faceOpacity',20,'edgeOpacity',50,'complexity',50)
                    actorgoe.changeSetting('colorFace',[0 1 1],'faceOpacity',20,'edgeOpacity',50,'complexity',50)
                    
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
            names{i} = [thisAtlas.group,' ',thisAtlas.hemisphere];
            regs{i} = thisAtlas;
        end
        names = [{'--','Native / Scanner','Suretune patient space','ACPC'},names];
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
            otherwise
                keyboard
        end
        
    end

    function [T,description] = universalCallbackRoutine(this)
        [names,regs] = getRegistrationlink(this);
        [selection] = listdlg('ListString',names);
        
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
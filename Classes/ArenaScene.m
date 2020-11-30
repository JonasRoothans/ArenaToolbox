classdef ArenaScene < handle
    %ARENASCENE Generates UIobjects, and stores Actors.
    %   Detailed explanation goes here
    
    properties
        Title
        Actors = ArenaActor.empty;
        handles
        SceneLocation = '';
    end
    
    properties (Hidden=true)
        configcontrolpos % stores the bounding box of the uicontrols
        colorTheme
        gitref
    end
    
    methods
        function obj = ArenaScene()
            %ARENAWINDOW Construct an instance of this class
            %   Detailed explanation goes here
        end
        
        function obj = create(obj,OPTIONALname)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            
            debugmode = 0;
            
            if debugmode
                userinput = {'debug mode'};
            else
                if nargin==1
                    userinput = newid({'new scene name: '},'Arena',1,{'test'});
                elseif nargin==2
                    userinput = {OPTIONALname};
                end
            end
            obj.Title = userinput{1};
            
            obj.handles = [];
            obj.handles.figure = figure('units','normalized',...
                'outerposition',[0 0.05 1 0.9],...
                'menubar','none',...
                'name',obj.Title,...
                'numbertitle','off',...
                'resize','on',...
                'UserData',obj,...
                'CloseRequestFcn',@closeScene,...
                'WindowKeyPressFcn',@keyShortCut,...
                'WindowButtonMotionFcn',@setcurrentpointlive,...
                'Color',[1 1 1]);
                %'WindowButtonDownFcn',@keyShortCut,...
      
            obj.handles.axes = axes('units','normalized',...
                'position',[0 0 1 1],...
                'fontsize',8,...
                'nextplot','add',...
                'box','off');
            axis off
            daspect([1 1 1])
            
            
            xpadding = 0.02;
            ypadding = 0.02;
            buttonheight = 0.04;
            obj.handles.panelleft = uipanel('units','normalized',...
                'position',[xpadding ypadding+buttonheight 0.4 0.3],...
                'Title','Config Controls');
            
            obj.handles.panelright = uicontrol('style','listbox',...
                'units','normalized',...
                'position',[1-xpadding-0.4 ypadding+buttonheight 0.4 0.3],...
                'callback',{@panelright_callback},...
                'max',100);
            
            obj.handles.btn_toggleleft = uicontrol('style','togglebutton',...
                'units','normalized',...
                'position', [xpadding,ypadding,0.4,buttonheight],...
                'String','close panel',...
                'Value',1,...
                'callback',{@btn_toggle_callback},...
                'Tag','left');
            
            obj.handles.btn_toggleright = uicontrol('style','togglebutton',...
                'units','normalized',...
                'position', [1-xpadding-0.4,ypadding,0.4,buttonheight],...
                'String','close panel',...
                'Value',1,...
                'callback',{@btn_toggle_callback},...
                'Tag','right');
            
            obj.handles.btn_updateActor = uicontrol('style','push',...
                'units','normalized',...
                'Parent',obj.handles.panelleft,...
                'position', [0.3,0.05,0.4,0.1],...
                'String','Update actor',...
                'Value',0,...
                'callback',{@btn_updateActor},...
                'Tag','UpdateButton');
            
            obj.handles.btn_layeroptions = uicontrol('style','push',...
                'units','normalized',...
                'position',[1-xpadding-0.05,ypadding+buttonheight+0.3,0.05,0.05],...
                'String','edit',...
                'Value',0,...
                'callback',{@btn_layeroptions});
            
            obj.handles.configcontrols = [];
            
            obj.handles.text_box_listSelectActor = uicontrol('parent',obj.handles.figure,...
                'style','text',...
                'units','normalized',...
                'position', [0.02,0.43,0.1,0.2],...
                'String','Select the Actor ...',...
                'Visible','off');
            
            obj.handles.box_listSelectActor = uicontrol('parent',obj.handles.figure,...
                'style','listbox',...
                'units','normalized',...
                'position', [0.02,0.4,0.1,0.2],...
                'String',' ',...
                'Visible','off',...
                'callback',{@box_listSelectActor});
            
            obj.handles.text_box_listSelectResult = uicontrol('parent',obj.handles.figure,...
                'style','text',...
                'units','normalized',...
                'position', [0.13,0.4,0.1,0.2],...
                'String','Select the Result ...',...
                'Visible','off');
            
            obj.handles.box_listSelectResult = uicontrol('parent',obj.handles.figure,...
                'style','listbox',...
                'units','normalized',...
                'position', [0.13,0.4,0.1,0.2],...
                'String',{},...
                'Visible','off',...
                'callback',{@box_listSelectResult});
            
            
            %menubar
            obj.handles.menu.file.main = uimenu(obj.handles.figure,'Text','File');
            
            obj.handles.menu.file.newscene.main = uimenu(obj.handles.menu.file.main,'Text','New empty scene','callback',{@menu_newscene});
            obj.handles.menu.file.savesceneas.main = uimenu(obj.handles.menu.file.main,'Text','Save scene as','callback',{@menu_savesceneas});
            obj.handles.menu.file.savescene.main = uimenu(obj.handles.menu.file.main,'Text','Save scene','callback',{@menu_savescene});
            obj.handles.menu.file.import.main = uimenu(obj.handles.menu.file.main,'Text','Import actor [cmd+i]','callback',{@menu_importAnything},'Enable','on','Separator','on');
            obj.handles.menu.file.export.main = uimenu(obj.handles.menu.file.main,'Text','Export');
            obj.handles.menu.file.export.wiggle = uimenu(obj.handles.menu.file.export.main,'Text','wiggle (*.mp4)','callback',{@menu_wiggle});
            obj.handles.menu.file.export.blender = uimenu(obj.handles.menu.file.export.main,'Text','Blender (*.obj)','callback',{@menu_exporttoblender});
            obj.handles.menu.file.export.handlestoworkspace = uimenu(obj.handles.menu.file.export.main,'Text','handles to workspace','callback',{@menu_exporthandlestoworkspace});
            obj.handles.menu.file.export.saveSelection = uimenu(obj.handles.menu.file.export.main,'Text','selection to folder','callback',{@menu_saveSelectionToFolder});
            obj.handles.menu.file.predict.main = uimenu(obj.handles.menu.file.main ,'Text','Prediction');
            obj.handles.menu.file.predict.calculation=uimenu(obj.handles.menu.file.predict.main,'Text','Calculate','Callback',{@menu_selectActorPrediction});
            obj.handles.menu.file.predict.results = uimenu(obj.handles.menu.file.predict.main,'Text','View Results','Callback',{@menu_viewActorResults},'Enable','off');
            obj.handles.menu.file.predict.close = uimenu(obj.handles.menu.file.predict.main,'Text','Close Prediction Windows','Callback',{@menu_closePredictionWindows},'Enable','off');
            obj.handles.menu.file.predict.showOldResults = uimenu(obj.handles.menu.file.predict.main,'Text','Show old Results','Callback',{@menu_showOldResults});

            
            obj.handles.menu.stusessions.main = uimenu(obj.handles.figure,'Text','Suretune sessions','Visible','off','Separator','on');
            obj.handles.menu.stusessions.openwindows = {};
            
            obj.handles.menu.view.main = uimenu(obj.handles.figure,'Text','View');
            obj.handles.menu.view.camera.main = uimenu(obj.handles.menu.view.main,'Text','Camera');
            obj.handles.menu.view.camera.focus.main = uimenu(obj.handles.menu.view.camera.main,'Text','Focus on');
            
            obj.handles.menu.view.camera.focus.actor = uimenu( obj.handles.menu.view.camera.focus.main,'Text','Selection [.]','callback',{@menu_camTargetActor});
            obj.handles.menu.view.camera.focus.origin = uimenu( obj.handles.menu.view.camera.focus.main,'Text','Origin [o]','callback',{@menu_camTargetOrigin});
            
            
            obj.handles.menu.view.camera.orthogonal.main = uimenu(obj.handles.menu.view.camera.main,'Text','Orthogonal');
             obj.handles.menu.view.camera.orthogonal.axial = uimenu(obj.handles.menu.view.camera.orthogonal.main,'Text','Axial [shift+1]','callback',{@menu_orthogonal});
             obj.handles.menu.view.camera.orthogonal.sagittal = uimenu(obj.handles.menu.view.camera.orthogonal.main,'Text','Sagittal [shift+2]','callback',{@menu_orthogonal});
             obj.handles.menu.view.camera.orthogonal.coronal = uimenu(obj.handles.menu.view.camera.orthogonal.main,'Text','Coronal [shift+3]','callback',{@menu_orthogonal});
             
             obj.handles.menu.view.camera.smart.main = uimenu(obj.handles.menu.view.camera.main,'Text','Smart Perspective');
             obj.handles.menu.view.camera.smart.vertical = uimenu(obj.handles.menu.view.camera.smart.main,'Text','based on selection','callback',{@menu_smartcamperspective});
            
             
             obj.handles.menu.view.camera.multi.cameralist = {};
             obj.handles.menu.view.camera.multi.currentcam = 1;
             obj.handles.menu.view.camera.multi.main = uimenu(obj.handles.menu.view.camera.main,'Text','Multi');
             obj.handles.menu.view.camera.multi.new = uimenu(obj.handles.menu.view.camera.multi.main,'Text','New Camera','callback',{@menu_camera_new});
             obj.handles.menu.view.camera.multi.cam{1} = uimenu(obj.handles.menu.view.camera.multi.main,'Text','1','Checked','on','Separator','on','callback',{@menu_camera_switch});
             
            
            
            obj.handles.menu.view.lights.main = uimenu(obj.handles.menu.view.main,'Text','Lights');
            obj.handles.menu.view.lights.visible = uimenu(obj.handles.menu.view.lights.main,'Text','visible','callback',{@menu_showLight},'Checked','on');
            obj.handles.menu.view.lights.cameraposition = uimenu(obj.handles.menu.view.lights.main,'Text','place light at camera position','callback',{@menu_placeLight});
            
            
            obj.handles.menu.view.flat.main = uimenu(obj.handles.menu.view.main,'Text','2D','Separator','on','callback',{@menu_intersectPlane});
            obj.handles.menu.view.bgcolor.main = uimenu(obj.handles.menu.view.main,'Text','background color');
            obj.handles.menu.view.bgcolor.white = uimenu(obj.handles.menu.view.bgcolor.main ,'Text','White','callback',{@menu_setbackgroundcolor});
            obj.handles.menu.view.bgcolor.light = uimenu(obj.handles.menu.view.bgcolor.main ,'Text','Light','callback',{@menu_setbackgroundcolor});
            obj.handles.menu.view.bgcolor.dark = uimenu(obj.handles.menu.view.bgcolor.main ,'Text','Dark','callback',{@menu_setbackgroundcolor});
            obj.handles.menu.view.bgcolor.black = uimenu(obj.handles.menu.view.bgcolor.main ,'Text','Black','callback',{@menu_setbackgroundcolor});
            obj.handles.menu.view.bgcolor.custom = uimenu(obj.handles.menu.view.bgcolor.main ,'Text','Custom','callback',{@menu_setbackgroundcolor});
            
            
            obj.handles.menu.atlas.main = uimenu(obj.handles.figure,'Text','Atlas');
            obj.handles.menu.atlas.lead.main = uimenu(obj.handles.menu.atlas.main,'Text','from leadDBS (MNI)','callback',{@menu_atlasleaddbs});
            obj.handles.menu.atlas.suretune.main = uimenu(obj.handles.menu.atlas.main ,'Text','from SureTune (legacy LPS)');
            obj.handles.menu.atlas.suretune.stn = uimenu(obj.handles.menu.atlas.suretune.main ,'Text','STN','callback',{@menu_legacyatlas});
            obj.handles.menu.atlas.suretune.gpi = uimenu(obj.handles.menu.atlas.suretune.main ,'Text','GPi','callback',{@menu_legacyatlas});
            obj.handles.menu.atlas.suretune.other = uimenu(obj.handles.menu.atlas.suretune.main ,'Text','Other','callback',{@menu_legacyatlas});

            
            obj.handles.menu.edit.main = uimenu(obj.handles.figure,'Text','Edit');
%            obj.handles.menu.edit.count.main = uimenu(obj.handles.menu.edit.main,'Text','count overlap');
%             obj.handles.menu.edit.count.toMesh = uimenu(obj.handles.menu.edit.count.main,'Text','as mesh','callback',{@menu_edit_count2mesh});
%             obj.handles.menu.edit.count.toPlane = uimenu(obj.handles.menu.edit.count.main,'Text','as plane','callback',{@menu_edit_count2plane});
%            obj.handles.menu.edit.add.main = uimenu(obj.handles.menu.edit.main,'Text','sum voxelvalues');
%             obj.handles.menu.edit.add.toMesh = uimenu(obj.handles.menu.edit.add.main,'Text','as mesh','callback',{@menu_edit_add2mesh});
%             obj.handles.menu.edit.add.toPlane = uimenu(obj.handles.menu.edit.add.main,'Text','as plane','callback',{@menu_edit_add2plane});
             obj.handles.menu.edit.getinfo.main = uimenu(obj.handles.menu.edit.main,'Text','get info','callback',{@menu_getinfo});
            obj.handles.menu.edit.analysis.main = uimenu(obj.handles.menu.edit.main,'Text','Analyse selection');
            
            
            
            obj.handles.menu.edit.analysis.sampleheatmap = uimenu(obj.handles.menu.edit.analysis.main,'Text','sample selection with ... ','callback',{@menu_sampleHeatmap});
            obj.handles.menu.edit.smooth = uimenu(obj.handles.menu.edit.main,'Text','Smooth VoxelData','callback',{@menu_smoothVoxelData});
            obj.handles.menu.edit.seperate = uimenu(obj.handles.menu.edit.main,'Text','separate clusters','callback',{@menu_seperateClusters});
            %obj.handles.menu.edit.intersectplane = uimenu(obj.handles.menu.edit.main,'Text','project to plane','callback',{@menu_intersectPlane});
            %obj.handles.menu.edit.pointclouddistribution = uimenu(obj.handles.menu.edit.main,'Text','pointcloud distribution','callback',{@menu_pcDistribution});
            %obj.handles.menu.edit.pointcloudanalysis = uimenu(obj.handles.menu.edit.main,'Text','PointCloud in mesh','callback',{@menu_pointcloudinmesh});
            
            
            obj.handles.menu.transform.main = uimenu(obj.handles.menu.edit.main,'Text','Transform'); %relocated
            obj.handles.menu.transform.selectedlayer.main = uimenu(obj.handles.menu.transform.main,'Text','Selected Layer');
            obj.handles.menu.transform.selectedlayer.lps2ras = uimenu(obj.handles.menu.transform.selectedlayer.main,'Text','LPS <> RAS','callback',{@menu_lps2ras});
            obj.handles.menu.transform.selectedlayer.mirror = uimenu(obj.handles.menu.transform.selectedlayer.main,'Text','mirror (makes copy)','callback',{@menu_mirror});
            obj.handles.menu.transform.selectedlayer.yeb2mni = uimenu(obj.handles.menu.transform.selectedlayer.main,'Text','Legacy --> MNI','callback',{@menu_Fake2MNI});
            obj.handles.menu.transform.selectedlayer.move =  uimenu(obj.handles.menu.transform.selectedlayer.main,'Text','Move','callback',{@menu_move});
            
            %-- dynamic
            obj.handles.menu.dynamic.main  = uimenu(obj.handles.figure,'Text','...');
            obj.handles.menu.dynamic.modify.main = uimenu(obj.handles.menu.dynamic.main ,'Text','Modify');
            obj.handles.menu.dynamic.analyse.main = uimenu(obj.handles.menu.dynamic.main ,'Text','Analyse');
            obj.handles.menu.dynamic.generate.main = uimenu(obj.handles.menu.dynamic.main ,'Text','Generate');            
            
            obj.handles.menu.dynamic.PointCloud.distribution = uimenu(obj.handles.menu.dynamic.analyse.main,'Text','PointCloud: show distribution','callback',{@menu_pcDistribution},'Enable','off');
            obj.handles.menu.dynamic.PointCloud.inMesh = uimenu(obj.handles.menu.dynamic.analyse.main,'Text','PointCloud: is a point inside a mesh?','callback',{@menu_pointcloudinmesh},'Enable','off');
            obj.handles.menu.dynamic.PointCloud.mergePointClouds = uimenu(obj.handles.menu.dynamic.generate.main,'Text','PointCloud: merge pointclouds','callback',{@menu_mergePointCloud},'Enable','off');
            obj.handles.menu.dynamic.PointCloud.twoSampleTTest = uimenu(obj.handles.menu.dynamic.analyse.main,'Text','PointCloud: two sample t-test','callback',{@menu_pc2samplettest},'Enable','off');
            
            obj.handles.menu.dynamic.Mesh.count2mesh  = uimenu(obj.handles.menu.dynamic.modify.main,'Text','Mesh: count overlap and show as mesh','callback',{@menu_edit_count2mesh},'Enable','off');
            obj.handles.menu.dynamic.Mesh.count2plane = uimenu(obj.handles.menu.dynamic.modify.main,'Text','Mesh: count overlap and show as plane','callback',{@menu_edit_count2plane},'Enable','off');
            %obj.handles.menu.dynamic.Mesh.add2mesh = uimenu(obj.handles.menu.dynamic.main,'Text','add up voxelvalues and show as mesh','callback',{@menu_edit_add2mesh},'Visible','off');
            %obj.handles.menu.dynamic.Mesh.add2plane = uimenu(obj.handles.menu.dynamic.main,'Text','add up voxelvalues and show as plane','callback',{@menu_edit_add2plane},'Visible','off');
            obj.handles.menu.dynamic.Mesh.getinfo = uimenu(obj.handles.menu.dynamic.analyse.main,'Text','Mesh: get info','callback',{@menu_getinfo},'Enable','off');
            obj.handles.menu.dynamic.Mesh.plotCOG = uimenu(obj.handles.menu.dynamic.analyse.main,'Text','Mesh: show COG','callback',{@menu_showCOG},'Enable','off');
            obj.handles.menu.dynamic.Mesh.dice = uimenu(obj.handles.menu.dynamic.analyse.main,'Text','Mesh: dice (=comformity of voxels)','callback',{@menu_dice},'Enable','off');
            obj.handles.menu.dynamic.Mesh.densitydistribution = uimenu(obj.handles.menu.dynamic.analyse.main,'Text','Mesh: FWHM (=density distribution)','callback',{@menu_fwhm},'Enable','off');
            obj.handles.menu.dynamic.Mesh.fibers = uimenu(obj.handles.menu.dynamic.generate.main,'Text','Mesh: fibers (from 1 seed)','callback',{@menu_showFibers},'Enable','off');
            obj.handles.menu.dynamic.Mesh.fibersBetween = uimenu(obj.handles.menu.dynamic.generate.main,'Text','Mesh: fibers (inbetween seeds)','callback',{@menu_showFibers_inbetween},'Enable','off');
            
            
            %obj.handles.cameratoolbar = cameratoolbar(obj.handles.figure,'Show');
            obj.handles.cameratoolbar = A_cameratoolbar(obj.handles.figure);
            obj.handles.light = camlight('headlight');
            obj.handles.light.Style = 'infinite';

            
            
            obj = createcoordinatesystem(obj);
            obj = setColorTheme(obj,'default');
            
            lighting gouraud
            camproj('perspective')
            view(30,30)
            
            function obj = createcoordinatesystem(obj)
                %Coordinate system
                h.XArrow = mArrow3([0 0 0],[3 0 0], 'facealpha', 0.5, 'color', 'red', 'stemWidth', 0.06,'Visible','off','Clipping','off');
                h.YArrow = mArrow3([0 0 0],[0 3 0], 'facealpha', 0.5, 'color', 'green', 'stemWidth', 0.06,'Visible','off','Clipping','off');
                h.ZArrow = mArrow3([0 0 0],[0 0 3], 'facealpha', 0.5, 'color', 'blue', 'stemWidth', 0.06,'Visible','off','Clipping','off');
                h.AC = text(-0.5,-0.5,-0.5,'MNI origin','Visible','off');
                h.R = text(4,0,0,'R','Visible','off');
                h.A = text(0,4,0,'A','Visible','off');
                h.S = text(0,0,4,'S','Visible','off');
                obj.handles.widgets.coordinatesystem = h;
            end
            
            
            function obj = setColorTheme(obj,name)
                switch name
                    case 'default'
                        obj.colorTheme = {[0 0.7373 0.84171],...
                                    [0.1804, 0.8, 0.4431],... %emerald
                                    [0.9451, 0.7686, 0.0588],...%SunFlower
                                    [0.9020, 0.4941, 0.133],... %Carrot
                                    [0.9059, 0.2980, 0.2353],... %Alizarin
                                    [0.607, 0.3490, 0.7137],... %Amethyst
                                    [0.2039,0.533,0.8588]*0.8,... %Peter river
                                    [0.2039, 0.2863, 0.3636],... %wet asphalt
                                    [0.9255, 0.9412, 0.9451],... %clouds
                                    [0.5843, 0.6471, 0.6510]}; %concrete
                                
                end
                
                obj.colorTheme = repmat(obj.colorTheme,[1,100]);
                        
            end
            
            %---figure functions
            function menu_showLight(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                switch hObject.Checked
                    case 'on'
                        scene.handles.light.Visible = 'off';
                        hObject.Checked = 'off';
                    case 'off'
                        scene.handles.light.Visible = 'on';
                        hObject.Checked = 'on';
                end
            end
            
            function menu_placeLight(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                camlight(scene.handles.light,'headlight')
            end
            
            function btn_toggle_callback(hObject,eventdata)
                %get link to the "ArenaScene" instance that is stored in UserData
                handles = hObject.Parent.UserData.handles;
                switch hObject.Value
                    case 0
                        set(handles.(['panel',hObject.Tag]),'Visible','off')
                        set(hObject,'String','open panel')
                    case 1
                        set(handles.(['panel',hObject.Tag]),'Visible','on')
                        set(hObject,'String', 'close panel')
                end
                handles.btn_layeroptions.Visible = handles.panelright.Visible;
                
            end
            
            function menu_newscene(hObject,eventdata)
                newScene;
            end
            
            function menu_cameratoolbar(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                switch scene.handles.cameratoolbar.main.Visible
                    case 'on'
                        scene.handles.cameratoolbar.main.Visible = 'off';
                        hObject.Checked = 'off';
                    case 'off'
                        scene.handles.cameratoolbar.main.Visible = 'on';
                        hObject.Checked = 'on';
                end
            end
            
            function import_scn(scene,file)
                
                
                loaded = load(file,'-mat');
                delete(gcf);
                %isSameVersion(loaded.Scene,'show')
                
                Actors = loaded.Scene.Actors;
                
                [indx] = listdlg('ListString',{Actors.Tag});
                for thisindex = indx
                    thisActor = Actors(thisindex);
                    thisActor.reviveInScene(scene);
                end
            end
            
            function menu_savesceneas(hObject,eventdata)
                Scene = ArenaScene.getscenedata(hObject);
                try
                    Scene.gitref = getGitInfo;
                catch
                    Scene.gitref = '';
                end
                [filename,pathname] = uiputfile('*.scn');
                save(fullfile(pathname,filename),'Scene');
                Scene.SceneLocation = fullfile(pathname,filename);
                disp('Scene saved')
                
            end
            
            function menu_savescene(hObject,eventdata)
                Scene = ArenaScene.getscenedata(hObject);
                try
                    Scene.gitref = getGitInfo;
                catch
                    Scene.gitref = '';
                end
                if isempty(Scene.SceneLocation)
                    [filename,pathname] = uiputfile('*.scn');
                    save(fullfile(pathname,filename),'Scene');
                    Scene.SceneLocation = fullfile(pathname,filename);
                else
                    save(Scene.SceneLocation,'Scene')
                end
                disp('Scene saved')
            end
            
            function menu_exporttoblender(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                actorList = scene.Actors;
                thisActor = actorList(scene.handles.panelright.Value);
                name = [thisActor.Tag,'.obj'];
                thisActor.export3d(name);
                
                disp('File saved to current directory')
            end
            
            function menu_exporthandlestoworkspace(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                assignin('base','scene',scene);
                assignin('base','actors',scene.Actors);
                disp('handles saved to workspace: scene, actors')
            end
            
            function menu_lps2ras(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                currentActors = ArenaScene.getSelectedActors(scene);
                
                for iActor = 1:numel(currentActors)
                    thisActor = currentActors(iActor);
                    thisActor.transform(scene,'lps2ras');
                    currentName = thisActor.Tag;
                    label = '[LPS <> RAS]  ';
                    if contains(currentName,label)
                        newname = erase(currentName,label);
                    else
                        newname = [label,currentName];
                    end
                    thisActor.changeName(newname)
                end
            end
            
            
            
            function menu_mirror(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                actorList = ArenaScene.getSelectedActors(scene);
                for iActor = 1:numel(actorList)
                    thisActor = actorList(iActor);
                
                    if isa(thisActor.Data,'Electrode')
                         eOriginal = thisActor.Data;
                         T = diag([-1 1 1 1]);
                         eNew = Electrode(SDK_transform3d(eOriginal.C0.getArray',T),...
                         SDK_transform3d(eOriginal.Direction.getArray',T));
                         eNew.Type = thisActor.Data.Type;
                        %vc = VectorCloud(Points(order(1)),direction.unit);
                        copyActor = eNew.see(ArenaScene.getscenedata(hObject));
                        copyActor.changeSetting('cathode',thisActor.Visualisation.settings.cathode);
                        copyActor.changeSetting('anode', thisActor.Visualisation.settings.anode);
                        copyActor.changeName([thisActor.Tag])

                    else
                    copyActor = thisActor.duplicate(scene);
                    copyActor.transform(scene,'mirror')
                    end
                    copyActor.changeName(['[mirror]  ',copyActor.Tag])
                end
                
                
            end
            
            function menu_showCOG(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                currentActors = ArenaScene.getSelectedActors(scene);
              
                for iActor = 1:numel(currentActors)
                    thisActor = currentActors(iActor);
                    thisCOG = PointCloud(thisActor.getCOG).see(scene);
                    thisCOG.changeName(['COG: ',thisActor.Tag])
                    thisCOG.changeSetting('colorLow',thisActor.Visualisation.settings.colorFace)
         
                end
                
            end
            
            
            function menu_move(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                currentActors = ArenaScene.getSelectedActors(scene);
                for i = 1:numel(currentActors)
                    thisActor = currentActors(i);
                    input = newid({'Translation vector: '},'Arena',1,{'[0 0 0]'});
                    T = eye(4);
                    input_v = eval(input{1});
                    T(1:3,4) = input_v;
                    thisActor.transform(scene,'T',T');
                  
                  
                end
            end
            
            
            
            function menu_Fake2MNI(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                currentActors = ArenaScene.getSelectedActors(scene);
                for i = 1:numel(currentActors)
                    thisActor = currentActors(i);
                    thisActor.transform(scene,'Fake2MNI');
                    currentName = thisActor.Tag;
                    label = '[MNI]  ';
                    if contains(currentName,label)
                        newname = erase(currentName,label);
                    else
                        newname = [label,currentName];
                    end
                    thisActor.changeName(newname)
                end
            end
                
            
            function menu_coordinatesystem(hObject,eventdata)
                thisScene = ArenaScene.getscenedata(hObject);
                cs_handle = thisScene.handles.widgets.coordinatesystem;
                switch hObject.Checked
                    case 'off'
                        fields=fieldnames(cs_handle);
                        for i = 1:numel(fields)
                            cs_handle.(fields{i}).Visible = 'on';
                        end
                        hObject.Checked = 'on';
                    case 'on'
                        fields=fieldnames(cs_handle);
                        for i = 1:numel(fields)
                            cs_handle.(fields{i}).Visible = 'off';
                        end
                        hObject.Checked  = 'off';
                end
            end
            function menu_setbackgroundcolor(hObject,eventdata)
                thisScene = ArenaScene.getscenedata(hObject);
                switch hObject.Text
                    case 'White'
                        color = [1 1 1];
                    case 'Light'
                        color = [0.92 0.9 0.88];
                    case 'Dark'
                        color = [0.5 0.53 0.53]*0.5;
                    case 'Black'
                        color = [0 0 0];
                    case 'Custom'
                        color =uisetcolor();
                end
                set(thisScene.handles.figure,'Color',color)
                
            end
            
            function menu_atlasleaddbs(hObject,eventdata)
                %get the rootdir to load the config file
                global arena;
                root = arena.getrootdir;
                loaded = load(fullfile(root,'config.mat'))
                leadDBSatlasdir = fullfile('templates','space','MNI_ICBM_2009b_NLIN_ASYM','atlases');
                
                subfolders = A_getsubfolders(fullfile(loaded.config.leadDBS,leadDBSatlasdir));
                
                
                [indx,tf] = listdlg('ListString',{subfolders.name},'ListSize',[400,320]);
                newAtlasPath = fullfile(loaded.config.leadDBS,...
                    leadDBSatlasdir,...
                    subfolders(indx).name,'atlas_index.mat');
                in = load(newAtlasPath);
                
                allnames = in.atlases.names;
                [indx,tf] = listdlg('ListString',allnames,'SelectionMode','multiple');
                thisScene = ArenaScene.getscenedata(hObject);
                for iAtlas = indx
                    R = in.atlases.fv{iAtlas,1};
                    
                    name = in.atlases.names{iAtlas};
                    color = in.atlases.colormap(round(in.atlases.colors(iAtlas)),:);
                    
                    meshR = Mesh(R.faces,R.vertices);
                    actorR = meshR.see(thisScene);
                    actorR.changeSetting('complexity',5,...
                        'colorFace',color,...
                        'colorEdge',color,...
                        'edgeOpacity',80);
                    
                    
                    
                    try
                        L = in.atlases.fv{iAtlas,2};
                        meshL = Mesh(L.faces,L.vertices);
                        actorL = meshL.see(thisScene);
                        actorL.changeName([name,' left'])
                        actorL.changeSetting('complexity',5,...
                            'colorFace',color,...
                            'colorEdge',color,...
                            'edgeOpacity',80)
                    catch
                        disp('unilateral?')
                        
                        
                    end
                    actorR.changeName([name,' right'])
                end
                
                
                %keyboard
            end
            
            function menu_legacyatlas(hObject,eventdata)
                %switch state
                rootdir = fileparts(fileparts(mfilename('fullpath')));
                legacypath = fullfile(rootdir,'Elements','SureTune');
                thisScene = ArenaScene.getscenedata(hObject);
                T = load('Tapproved.mat');
 
 
                        
                        switch hObject.Text
                            case 'STN'
                                obj_stn = ObjFile(fullfile(legacypath,'LH_STN-ON-pmMR.obj'));
                                obj_rn = ObjFile(fullfile(legacypath,'LH_RU-ON-pmMR.obj'));
                                obj_sn = ObjFile(fullfile(legacypath,'LH_SN-ON-pmMR.obj'));
                                
                                obj_stn_left = obj_stn.transform(T.leftstn2mni);
                                obj_stn_right = obj_stn.transform(T.rightstn2mni);
                                obj_rn_left = obj_rn.transform(T.leftstn2mni);
                                obj_rn_right = obj_rn.transform(T.rightstn2mni);
                                obj_sn_left = obj_sn.transform(T.leftstn2mni);
                                obj_sn_right = obj_sn.transform(T.rightstn2mni);
                                
                                [thisScene.handles.atlas.legacy.Actor_stnleft,scene] = obj_stn_left.see(thisScene);
                                [thisScene.handles.atlas.legacy.Actor_snleft,scene] = obj_sn_left.see(thisScene);
                                [thisScene.handles.atlas.legacy.Actor_rnleft,scene] = obj_rn_left.see(thisScene);
                                [thisScene.handles.atlas.legacy.Actor_stnright,scene] = obj_stn_right.see(thisScene);
                                [thisScene.handles.atlas.legacy.Actor_snright,scene] = obj_sn_right.see(thisScene);
                                [thisScene.handles.atlas.legacy.Actor_rnright,scene] = obj_rn_right.see(thisScene);
                                
                                
                                thisScene.handles.atlas.legacy.Actor_stnleft.changeSetting('colorFace',[0 1 0],'faceOpacity',20,'edgeOpacity',0,'complexity',10)
                                thisScene.handles.atlas.legacy.Actor_snleft.changeSetting('colorFace',[1 1 0],'faceOpacity',20,'edgeOpacity',0,'complexity',10)
                                thisScene.handles.atlas.legacy.Actor_rnleft.changeSetting('colorFace',[1 0 0],'faceOpacity',20,'edgeOpacity',0,'complexity',10)
                                thisScene.handles.atlas.legacy.Actor_stnright.changeSetting('colorFace',[0 1 0],'faceOpacity',20,'edgeOpacity',0,'complexity',10)
                                thisScene.handles.atlas.legacy.Actor_snright.changeSetting('colorFace',[1 1 0],'faceOpacity',20,'edgeOpacity',0,'complexity',10)
                                thisScene.handles.atlas.legacy.Actor_rnright.changeSetting('colorFace',[1 0 0],'faceOpacity',20,'edgeOpacity',0,'complexity',10)
                                
                                
                                thisScene.handles.atlas.legacy.Actor_stnleft.changeName('[legacy] STNleft')
                                thisScene.handles.atlas.legacy.Actor_snleft.changeName('[legacy] SNleft')
                                thisScene.handles.atlas.legacy.Actor_rnleft.changeName('[legacy] RNleft')
                                thisScene.handles.atlas.legacy.Actor_stnright.changeName('[legacy] STNright')
                                thisScene.handles.atlas.legacy.Actor_snright.changeName('[legacy] SNright')
                                thisScene.handles.atlas.legacy.Actor_rnright.changeName('[legacy] RNright')
                                
                            case 'GPi'
                                obj_gpi = ObjFile(fullfile(legacypath,'LH_IGP-ON-pmMR.obj'));
                                obj_gpe = ObjFile(fullfile(legacypath,'LH_EGP-ON-pmMR.obj'));
                                
                                obj_gpi_left = obj_gpi.transform(T.leftgpi2mni);
                                obj_gpe_left = obj_gpe.transform(T.leftgpi2mni);
                                obj_gpi_right = obj_gpi.transform(T.rightgpi2mni);
                                obj_gpe_right = obj_gpe.transform(T.rightgpi2mni);
                                
                                [thisScene.handles.atlas.legacy.Actor_gpileft,scene] = obj_gpi_left.see(thisScene);
                                [thisScene.handles.atlas.legacy.Actor_gpeleft,scene] = obj_gpe_left.see(thisScene);
                                [thisScene.handles.atlas.legacy.Actor_gpiright,scene] = obj_gpi_right.see(thisScene);
                                [thisScene.handles.atlas.legacy.Actor_gperight,scene] = obj_gpe_right.see(thisScene);
                                
                                
                                
                                thisScene.handles.atlas.legacy.Actor_gpileft.changeSetting('colorFace',[0 0 1],'faceOpacity',20,'edgeOpacity',0,'complexity',10)
                                thisScene.handles.atlas.legacy.Actor_gpeleft.changeSetting('colorFace',[0 1 1],'faceOpacity',20,'edgeOpacity',0,'complexity',10)
                                thisScene.handles.atlas.legacy.Actor_gpiright.changeSetting('colorFace',[0 0 1],'faceOpacity',20,'edgeOpacity',0,'complexity',10)
                                thisScene.handles.atlas.legacy.Actor_gperight.changeSetting('colorFace',[0 1 1],'faceOpacity',20,'edgeOpacity',0,'complexity',10)
                                
                                thisScene.handles.atlas.legacy.Actor_gpileft.changeName('[legacy] GPIleft')
                                thisScene.handles.atlas.legacy.Actor_gpeleft.changeName('[legacy] GPEeft')
                                thisScene.handles.atlas.legacy.Actor_gpiright.changeName('[legacy] GPIright')
                                thisScene.handles.atlas.legacy.Actor_gperight.changeName('[legacy] GPRright')
                                
                            case 'Other'
                                %keyboard
                                atlases = uigetfile(fullfile(legacypath,'*.obj'),'MultiSelect','On');
                                if not(iscell(atlases))
                                    atlases = {atlases};
                                end
                                for iAtlas = 1:numel(atlases)
                                    obj_custom = ObjFile(fullfile(legacypath,atlases{iAtlas}));
                                    obj_custom_left = obj_custom.transform(T.leftstn2mni);
                                    obj_custom_right = obj_custom.transform(T.rightstn2mni);
                                    [thisScene.handles.atlas.legacy.(['Actor_obj_custom_',num2str(iAtlas),'_left'])] = obj_custom_left.see(thisScene);
                                    [thisScene.handles.atlas.legacy.(['Actor_obj_custom_',num2str(iAtlas),'_right'])] = obj_custom_right.see(thisScene);
                                    
                                    
                                    thisScene.handles.atlas.legacy.(['Actor_obj_custom_',num2str(iAtlas),'_left']).changeSetting('colorFace',[0.5 0.5 0.5],'faceOpacity',20,'edgeOpacity',0,'complexity',10)
                                    thisScene.handles.atlas.legacy.(['Actor_obj_custom_',num2str(iAtlas),'_right']).changeSetting('colorFace',[0.5 0.5 0.5],'faceOpacity',20,'edgeOpacity',0,'complexity',10)
                                    
                                    
                                     thisScene.handles.atlas.legacy.(['Actor_obj_custom_',num2str(iAtlas),'_left']).changeName(['[legacy] ',atlases{iAtlas},' left'])
                                     thisScene.handles.atlas.legacy.(['Actor_obj_custom_',num2str(iAtlas),'_right']).changeName(['[legacy] ',atlases{iAtlas},' right'])
                                end
                                
                                
                                
                        end
                        
                    
                
                
                
                
            end
            
            
            function import_mat(thisScene,filename)
               
                
                loaded = load(filename);
                names = {};
                data = {};
                
                vars = fieldnames(loaded);
                for iVariable = 1:numel(vars)
                    thisVariable = loaded.(vars{iVariable});
                    switch class(thisVariable)
                        case 'PointCloud'
                            names{end+1} = vars{iVariable};
                            data{end+1} = thisVariable;
                        case 'double'
                            if any(size(thisVariable)==3)
                                names{end+1} = vars{iVariable};
                                data{end+1} = thisVariable;
                            end
                    end
                end
                
                [indx] = listdlg('ListString',names);
                for thisindex = indx
                    pc = PointCloud(data{thisindex});
                    actor = pc.see(thisScene);
                    actor.changeName(names{thisindex})
                end
            end
            
            
            
            function menu_importscatterfromworkspace(hObject,eventdata)
                thisScene =  ArenaScene.getscenedata(hObject);
                names = {};
                data = {};
                
                basevariables = evalin('base','whos');
                for iVariable = 1:numel(basevariables)
                    thisVariable = evalin('base',basevariables(iVariable).name);
                    switch class(thisVariable)
                        case 'PointCloud'
                            names{end+1} = basevariables(iVariable).name;
                            data{end+1} = thisVariable;
                        case 'double'
                            if any(size(thisVariable)==3)
                                names{end+1} = basevariables(iVariable).name;
                                data{end+1} = thisVariable;
                            end
                    end
                end
                
                [indx] = listdlg('ListString',names);
                for thisindex = indx
                    pc = PointCloud(data{thisindex});
                    [actor,scene] = pc.see(thisScene);
                    actor.changeName(names{thisindex})
                end
                
            end
            
            
            

            
 
            
 
            
            function [actor,threshold] = import_nii_mesh(scene,data,name,threshold)
                
                if nargin<4
                    threshold = nan;
                end
                
                if isempty(data.Voxels)
                        return
                end
                    if data.isBinary
                        actor = data.getmesh(0.5).see(scene);
                    else
                        if isnan(threshold) %ask for threshold
                            [mesh] = data.getmesh;
                            actor = mesh.see(scene);
                            threshold = mesh.Settings.T;
                        else %use previously defined threshold
                            actor = data.getmesh(threshold).see(scene);
                        end
                    end
                    actor.changeName(name)
            end
            
            function actor = import_nii_plane(scene,data,name)
                v = data;
                if isempty(v.Voxels)
                    return
                end
                actor = v.getslice.see(scene);
                actor.changeName(name);
            end
            
            
%             function menu_importimageasmesh(hObject,eventdata)
%                 
%                 [filename,pathname] = uigetfile('*.nii','Find nii image(s)','MultiSelect','on');
%                 try
%                 if filename==0
%                     return
%                 end
%                 catch
%                 end
%                 if not(iscell(filename));filename = {filename};end
%                 
%                 for iFile = 1:numel(filename)
%                     niifile = fullfile(pathname,filename{iFile});
%                     v = VoxelData;
%                     [~, name] = v.loadnii(niifile);
%                     if isempty(v.Voxels)
%                         return
%                     end
%                     
%                     if v.isBinary
%                         actor = v.getmesh(0.5).see(ArenaScene.getscenedata(hObject));
%                     else
%                         actor = v.getmesh.see(ArenaScene.getscenedata(hObject));
%                     end
%                     actor.changeName(name)
%                 end
%                 
%            end

            function actor = import_obj(scene,filename)
                o = ObjFile;
                [~,layername,~] = fileparts(filename);
                o = o.loadfile(filename);
                actor  = o.see(scene);
                actor.changeName(layername);
            end
            
            function menu_importAnything(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                if ispc                                     %this is only valid for Windows
                [filename,pathname] = uigetfile({'*.nii','nifti files (*.nii)';...
                    '*.obj','3d object files (*.obj)';...
                    '*.swtspt','sweetspots (*.swtspt)';...
                    '*.scn','scenes (*.scn)';...
                    '*.mat','matlab data (*.mat)'},...
                    'import actors','MultiSelect','on');
                else
                    [filename,pathname] = uigetfile('*.*',...
                    'import actors','MultiSelect','on');
                end
                
                try
                if filename==0
                    return
                end
                catch
                end
                if not(iscell(filename));filename = {filename};end
                
                
                nii_mesh_threshold = nan; 
                for iFile = 1:numel(filename)
                
                    [~,name,ext] = fileparts(filename{iFile});
                    switch ext
                        case '.nii'
                            v = VoxelData;
                            v.loadnii(fullfile(pathname,filename{iFile}));
                            if v.isBinary(80) 
                                [~,nii_mesh_threshold] = import_nii_mesh(scene,v,name,nii_mesh_threshold);
                            else
                                import_nii_plane(scene,v,name);
                            end
                        case '.obj'
                            import_obj(scene,fullfile(pathname,filename{iFile}))
                        case '.scn'
                            import_scn(scene,fullfile(pathname,filename{iFile}))
                        case '.mat'
                            import_mat(thisScene,fullfile(pathname,filename{iFile}))
                        case '.swtspt'
                            A_loadsweetspot(scene);
                        case '.dcm' 
                            addSuretuneSession(scene,fullfile(pathname,filename{iFile}))
                          
                            
                            
                        otherwise
                            disp(['file: ',name,ext,' not supported.'])
                    end
                end
            end
            
%             function menu_imoprtimageasslice(hObject,eventdata)
%                 v = VoxelData;
%                 v.loadnii;
%                 if isempty(v.Voxels)
%                     return
%                 end
%                 v.getslice.see(ArenaScene.getscenedata(hObject));
%                 
%             end
            
            function addSuretuneSession(scene,dcmpath)
                STU_object = SuretunePortal(scene,dcmpath);
                obj.handles.menu.stusessions.openwindows{end+1} = uimenu(obj.handles.menu.stusessions.main,'Text',STU_object.session.patient.name,'Callback',{@suretuneportal_callback},'UserData',STU_object);
                obj.handles.menu.stusessions.main.Visible = 'on';
            end
            
            function suretuneportal_callback(hObject,eventdata)
                figure(hObject.UserData.handles.f); %pop-up the portal
            end
            
            function menu_importleadfromnii(hObject,eventdata)
                [filename,pathname] = uigetfile('*.nii','Find nii image(s)','MultiSelect','on');
                if not(iscell(filename));filename = {filename};end
                for iFile = 1:numel(filename)
                    niifile = fullfile(pathname,filename{iFile});
                    v = VoxelData;
                    [~, name] = v.loadnii(niifile);
                    Points = v.detectPoints();
                    
                    [~,order] = sort([Points.z]);% From lowest to highest
                    direction = (Points(order(2))-Points(order(1)));
                    e = Electrode(Points(order(1)),direction.unit);
                    %vc = VectorCloud(Points(order(1)),direction.unit);
                    actor = e.see(ArenaScene.getscenedata(hObject));
                    actor.changeName(name)
                end
                
            end
            
            function menu_edit_count2mesh(hObject,eventdata)
                
                vd = ArenaScene.countMesh(hObject);
                vd.getmesh.see(ArenaScene.getscenedata(hObject)) 
            end
            
            function menu_camTargetActor(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                currentActor = ArenaScene.getSelectedActors(scene);

                        for iActor = 1:numel(currentActor)
                            try
                            cog = currentActor.getCOG;
                            
                             easeCamera([], cog.getArray',[],10) %pos, target  
         
                            catch
                                error(['getCOG (center of gravity) function does not exist yet for this type of data: ',class(currentActor.Data)])
                            end
                  
                        end
            end
            
            function easeCamera(end_pos, end_target, end_up,easeTime)
                
                if isempty(end_pos)
                    end_pos = campos;
                end
                
                if isempty(end_target)
                    end_target = camtarget;
                end
                
                if nargin==2
                    end_up = camup;
                else
                    if isempty(end_up)
                        end_up = camup;
                    end
                end
                
                original_pos = campos;
                original_target = camtarget;
                original_camva = camva;
                original_up = camup;
                
                if nargin<4
                easeTime = 20;
                end
                        for t = 1:easeTime
                            
                            tlog = easeTime./(1+exp(-0.5*(t-easeTime/2)));

                            campos(tlog/easeTime*end_pos + (1-tlog/easeTime)*original_pos)
                        	camtarget(tlog/easeTime*end_target + (1-tlog/easeTime)*original_target)
                            camup(tlog/easeTime*end_up + (1-tlog/easeTime)*original_up)
                            %camva(tlog/easeTime*end_camva + (1-tlog/easeTime)*original_camva)
                            drawnow
                        end
                        
                        campos(end_pos)
                        camtarget(end_target)
                        camup(end_up)
            end
            
            function menu_camTargetOrigin(hObject,eventdata)
                easeCamera([], [0 0 0]) %pos, target  
            end
            
            
            function menu_camera_switch(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                current_cam = scene.handles.menu.view.camera.multi.currentcam;
                
                %save current location
                scene.handles.menu.view.camera.multi.cameralist(current_cam).campos = campos;
                scene.handles.menu.view.camera.multi.cameralist(current_cam).camtarget = camtarget;
                scene.handles.menu.view.camera.multi.cameralist(current_cam).camup = camup;
                scene.handles.menu.view.camera.multi.cam{current_cam}.Checked = 'off';
                
                %load selected cam
                selected_cam = str2num(hObject.Text);
                if selected_cam > numel(scene.handles.menu.view.camera.multi.cameralist);
                    return
                end
                easeCamera(scene.handles.menu.view.camera.multi.cameralist(selected_cam).campos,...
                    scene.handles.menu.view.camera.multi.cameralist(selected_cam).camtarget,...
                    scene.handles.menu.view.camera.multi.cameralist(selected_cam).camup,10)%end_pos, end_target, end_up,easeTime
                
                
                scene.handles.menu.view.camera.multi.cam{selected_cam}.Checked = 'on';
                scene.handles.menu.view.camera.multi.currentcam = selected_cam;
                
                
               
            end
            
            
            
            function menu_camera_new(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                current_cam = scene.handles.menu.view.camera.multi.currentcam;
                
                if isempty(scene.handles.menu.view.camera.multi.cameralist)
                    new_cam = 2;
                else
                    new_cam = numel(scene.handles.menu.view.camera.multi.cameralist)+1;
                end
                
                %save current location
                scene.handles.menu.view.camera.multi.cameralist(current_cam).campos = campos;
                scene.handles.menu.view.camera.multi.cameralist(current_cam).camtarget = camtarget;
                scene.handles.menu.view.camera.multi.cameralist(current_cam).camup = camup;
                
                scene.handles.menu.view.camera.multi.cam{current_cam}.Checked = 'off';
                
                
                
                %--show icon here in the future
                
                
                %make new camera object
                scene.handles.menu.view.camera.multi.cam{new_cam} = uimenu(scene.handles.menu.view.camera.multi.main,'Text',num2str(new_cam),'Checked','on','callback',{@menu_camera_switch});
                scene.handles.menu.view.camera.multi.cameralist(new_cam).campos = campos;
                scene.handles.menu.view.camera.multi.cameralist(new_cam).camtarget = camtarget;
                scene.handles.menu.view.camera.multi.cameralist(new_cam).camup = camup;
                
                
                
                
                
                scene.handles.menu.view.camera.multi.currentcam = new_cam;
                
                
                
                
             
            end
            
            function menu_wiggle(hObject,eventdata)
                
                scene = ArenaScene.getscenedata(hObject);
                 original_pos = campos;
                 original_target = camtarget;
                 original_up = camup;
                 
                 eyeline = original_target- original_pos;
                 distance = norm(eyeline);
                 side = cross(Vector3D(eyeline).unit,Vector3D(original_up).unit);
                 updown = original_up;
                 
                 %current status
                 pleft = scene.handles.panelleft.Visible;
                 pright = scene.handles.panelright.Visible;
                 tleft = scene.handles.btn_toggleleft.Visible;
                 tright = scene.handles.btn_toggleright.Visible;
                 layeroptions = scene.handles.btn_layeroptions.Visible;
                 
                 
                 
               %hide panels  
                scene.handles.panelleft.Visible = 'off';
                scene.handles.panelright.Visible = 'off';
                scene.handles.btn_toggleleft.Visible = 'off';
                scene.handles.btn_toggleright.Visible = 'off';
                scene.handles.btn_layeroptions.Visible = 'off';
                 
                 %make mp4 object:
                 
                 [filename,pathname] = uiputfile([scene.Title,'.mp4'],'export wiggle video');
                 outputVideo = VideoWriter( fullfile(pathname,filename), 'MPEG-4');
                outputVideo.FrameRate = 30;
                open(outputVideo);
                 
                imstorage = {};
                 for deg = 1:10:360
                     campos(original_pos + side.getArray' * cos(deg2rad(deg))*distance/20 + sin(deg2rad(deg))*updown*distance/20)
                     drawnow
                     frame = getframe(scene.handles.figure);
                     imstorage{end+1} = frame2im(frame);
                 end
                 
                 for loop = 1:5
                     for frame = 1:numel(imstorage)
                        writeVideo(outputVideo,imstorage{frame});
                     end
                 end
                 
                 campos(original_pos);
                 close(outputVideo);
                 clear imstorage
                 
                 %show panels again
                 scene.handles.panelleft.Visible = pleft;
                    scene.handles.panelright.Visible = pright;
                    scene.handles.btn_toggleleft.Visible = 'on';
                    scene.handles.btn_toggleright.Visible = 'on';
                    scene.handles.btn_layeroptions.Visible = layeroptions;
 
            end
            
            function menu_smartcamperspective(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                currentActors = ArenaScene.getSelectedActors(scene);
                allClasses = ArenaScene.getClasses(currentActors);
                
                if all(contains(allClasses,'PointCloud'))
                    allVectors = [];
                    for iActor = 1:numel(currentActors)
                        thisActor = currentActors(iActor);
                        allVectors = [allVectors;thisActor.Data.Vectors.getArray];
                    end
                    orientations = pca(allVectors);
                    
                   
                    original_distance = norm(abs(campos-camtarget));
                    end_target = mean(allVectors);
                    
                    %choose the camera direction that is closest to the
                    %current direction:
                    cam_option_a =  norm(orientations(:,3)'*original_distance - (camtarget-campos)) ;
                    cam_option_b =  norm(-orientations(:,3)'*original_distance - (camtarget-campos));
                    if cam_option_a > cam_option_b
                        cam_distance = orientations(:,3)'*original_distance;
                    else
                        cam_distance = -orientations(:,3)'*original_distance;
                    end
                    end_pos = end_target+cam_distance;
                    
                    
                    %choose coefficient that is closest Z-axis for camup
                    [~,pcavertical] = max(abs(orientations(3,[1,2])));
                    upvector = orientations(:,pcavertical);
                    if upvector(3)<0
                        upvector = -upvector;
                    end

                    
                    easeCamera(end_pos, end_target,upvector')
                    
                    
         
                    %merge pointclouds
                else
                    warning('Define what a smart perspective is for a mixed selection!')
                    keyboard
                    
                end
                
                
            end
                
            
            function menu_orthogonal(hObject,eventdata)
                camva('manual')
                switch hObject.Text
                    case {'axial plane','Axial [shift+1]'}
                        original_pos = campos;
                        original_target = camtarget;
                        original_camva = camva;
                        original_up = camup;
                        
                        end_pos = [original_target(1) original_target(2) norm(original_pos-original_target)]; %[0 0 1000];
                        end_target = original_target;%[0 0 0];
                        end_up = [0 1 0];
                        end_camva = 20;
                        
                        easeTime = 20;
                        for t = 1:easeTime
                            
                            tlog = easeTime./(1+exp(-0.5*(t-easeTime/2)));

                            campos(tlog/easeTime*end_pos + (1-tlog/easeTime)*original_pos)
                        	camtarget(tlog/easeTime*end_target + (1-tlog/easeTime)*original_target)
                            camup(tlog/easeTime*end_up + (1-tlog/easeTime)*original_up)
                            %camva(tlog/easeTime*end_camva + (1-tlog/easeTime)*original_camva)
                            drawnow
                        end
                        
                        campos(end_pos)
                        camtarget(end_target)
                        camup(end_up)
                        %camva(end_camva)

                    case {'coronal plane','Coronal [shift+3]'}
                        original_pos = campos;
                        original_target = camtarget;
                        original_camva = camva;
                        original_up = camup;
                        
                         frontorback = sign(original_pos);
                        frontorback(frontorback==0) = 1;
                        
                        end_pos = [0 norm(original_pos-original_target) 0].*frontorback;
                        end_target = original_target;%[0 0 0];
                        end_up = [0 0 1];
                        end_camva = 20;
                        
                        easeTime = 20;
                        for t = 1:easeTime
                            
                            tlog = easeTime./(1+exp(-0.5*(t-easeTime/2)));

                            campos(tlog/easeTime*end_pos + (1-tlog/easeTime)*original_pos)
                        	camtarget(tlog/easeTime*end_target + (1-tlog/easeTime)*original_target)
                            camup(tlog/easeTime*end_up + (1-tlog/easeTime)*original_up)
                            %camva(tlog/easeTime*end_camva + (1-tlog/easeTime)*original_camva)
                            drawnow
                        end
                        
                        campos(end_pos)
                        camtarget(end_target)
                        camup(end_up)
                        %camva(end_camva)
                    case {'sagittal plane','Sagittal [shift+2]'}
                        original_pos = campos;
                        original_target = camtarget;
                        original_camva = camva;
                        original_up = camup;
                        
                        leftorright = sign(original_pos);
                        leftorright(leftorright==0) = 1;
                        
                        end_pos = [norm(original_pos-original_target) 0 0].*leftorright;
                        end_target = original_target;%[0 0 0];
                        end_up = [0 0 1];
                        %end_camva = 20;
                        
                        easeTime = 20;
                        for t = 1:easeTime
                            
                            tlog = easeTime./(1+exp(-0.5*(t-easeTime/2)));

                            campos(tlog/easeTime*end_pos + (1-tlog/easeTime)*original_pos)
                        	camtarget(tlog/easeTime*end_target + (1-tlog/easeTime)*original_target)
                            camup(tlog/easeTime*end_up + (1-tlog/easeTime)*original_up)
                            %camva(tlog/easeTime*end_camva + (1-tlog/easeTime)*original_camva)
                            drawnow
                        end
                        
                        campos(end_pos)
                        camtarget(end_target)
                        camup(end_up)
                        %camva(end_camva)
                        
                      
                end
                drawnow
            end
                
            
            
            function menu_edit_count2plane(hObject,eventdata)
                vd = ArenaScene.countMesh(hObject);
                vd.getslice.see(ArenaScene.getscenedata(hObject))
            end
            
            
            function menu_saveSelectionToFolder(hObject,eventdata)
                outdir = uigetdir('select output directory');
                if outdir==0
                    return
                end
                
                
                scene = ArenaScene.getscenedata(hObject);
                currentActors = ArenaScene.getSelectedActors(scene);
              
                for iActor = 1:numel(currentActors)
                    thisActor = currentActors(iActor);
                    thisActor.saveToFolder(outdir)
                    
                end
                
                
            end
            
            function menu_pointcloudinmesh(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                labels_pc = {};
                actors_pc = {};
                for iActor = 1:numel(scene.Actors)
                    if isa(scene.Actors(iActor).Data,'PointCloud')
                        labels_pc{end+1} = scene.Actors(iActor).Tag;
                        actors_pc{end+1} = scene.Actors(iActor);
                    end
                end
                
                  labels_mesh = {};
                  actors_mesh = {};
                for iActor = 1:numel(scene.Actors)
                    if isprop(scene.Actors(iActor).Data,'Vertices')
                        labels_mesh{end+1} = scene.Actors(iActor).Tag;
                        actors_mesh{end+1} = scene.Actors(iActor);
                    end
                end
                
                %abort?
                if isempty(labels_pc);disp('No Pointclouds available');return;end
                if isempty(labels_mesh);disp('No Meshes available'); return;end
            
                [indx_pc,tf] = listdlg('PromptString',{'Select pointclouds'},'ListString',labels_pc);
                [indx_mesh,tf] = listdlg('PromptString',{'Select meshes'},'ListString',labels_mesh);
                
                results = [];
                
                
                for iPC = 1:numel(indx_pc)
                    thisPC = actors_pc{indx_pc(iPC)};
                    coordinates = thisPC.Data.Vectors.getArray;
                    identified = zeros(numel(thisPC.Data.Vectors),1);
                    for iMesh = 1:numel(indx_mesh)
                        thisMesh = actors_mesh{indx_mesh(iMesh)};
                        
                        fv.faces = thisMesh.Visualisation.handle.Faces;
                        fv.vertices = thisMesh.Visualisation.handle.Vertices;
                        
                        answer = inpolyhedron(fv,coordinates(:,[1,2,3]),'flipnormals', true);
                        results(iPC,iMesh) = sum(answer);
                        
                        
                        identified = identified+answer; 
                    end
                    results(iPC,iMesh+1) = sum(not(identified));
                end
                
                q_answer = questdlg('What kind of bar chart do you like?','Arena','stacked','side by side','stacked');
                
                if strcmp(q_answer,'stacked')
                    f = figure;b = bar(results','stacked');
                else
                    f = figure;b = bar(results');
                end
                   
                title('Grouped per anatomical location')
                for iB = 1:numel(b)
                    b(iB).FaceColor = actors_pc{indx_pc(iB)}.Visualisation.settings.colorLow;
                end
                
                Xlabels = [labels_mesh(indx_mesh),{'other'}];
                set(gca, 'XTickLabel', Xlabels)
                legend(labels_pc(indx_pc))
                
                 if strcmp(q_answer,'stacked')
                    f = figure;b = bar(results,'stacked');
                else
                    f = figure;b = bar(results);
                 end
                title('Grouped per pointcloud')
                for iB = 1:numel(b)
                    try
                    b(iB).FaceColor = actors_mesh{indx_mesh(iB)}.Visualisation.settings.colorFace;
                    catch
                        b(iB).FaceColor = [1 1 1]
                    end
                end
                
                Xlabels = [labels_pc(indx_pc)];
                set(gca, 'XTickLabel', Xlabels)
                legend([labels_mesh(indx_mesh),{'other'}])
                
            end
            
            function  menu_pc2samplettest(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                currentActors = ArenaScene.getSelectedActors(scene);
                
                if not(numel(currentActors)==2)
                    error('please select two pointclouds for this TWO SAMPLE t-test')
                end
                
                sample1 = currentActors(1).Data.Vectors;
                sample2 = currentActors(2).Data.Vectors;
                
                %1. Run it along x, y and z
                result = [];
                dimtext = {'x','y','z'};
               
                for dim = 1:3
                    [result.(dimtext{dim}).h,result.(dimtext{dim}).p,result.(dimtext{dim}).ci,result.(dimtext{dim}).stats] = ttest2([sample1.(dimtext{dim})],[sample2.(dimtext{dim})]);
                    result.(dimtext{dim}).vector = Vector3D(double(1:3==dim));
                    disp([dimtext{dim},'--> p= ',num2str(result.(dimtext{dim}).p)])
                    
                end
                
                %2. also run a along PCA components.
                %Principle component analysis finds th axes that spreads your data optimally. 
                allData = [sample1.getArray;sample2.getArray];
                [directions,loadings] = pca(allData);
                [result.pca1.h,result.pca1.p,result.pca1.ci,result.pca1.stats] = ttest2(loadings(1:numel(sample1),1),loadings(numel(sample1)+1:end,1));
                result.pca1.vector= Vector3D(directions(:,1));
                disp(['pca1 --> p= ',num2str(result.pca1.p)])
                [result.pca2.h,result.pca2.p,result.pca2.ci,result.pca2.stats] = ttest2(loadings(1:numel(sample1),2),loadings(numel(sample1)+1:end,2));
                result.pca2.vector= Vector3D(directions(:,2));
                disp(['pca2 --> p= ',num2str(result.pca2.p)])
                
                %3. run along the major discriminating axis
                main_axis = Vector3D(mean(sample1.getArray) - mean(sample2.getArray)).unit.getArray'; %makes axis: x'
                allData = [sample1.getArray;sample2.getArray];
                projection = main_axis*allData';
                
                %dimension reduction: proj = v - (e*v)*e = v - d_*e;
                v = allData;
                d_ = repmat(projection,3,1)';
                e = repmat(Vector3D(main_axis).unit.getArray',length(projection),1);
                dimred = v - d_.*e;
                [directions,loadings] = pca(dimred);
                
                [result.proj1.h,result.proj1.p,result.proj1.ci,result.proj1.stats] = ttest2(projection(1:numel(sample1)),projection(numel(sample1)+1:end));
                [result.proj2.h,result.proj2.p,result.proj2.ci,result.proj2.stats] = ttest2(loadings(1:numel(sample1),1),loadings(numel(sample1)+1:end,1));
                [result.proj3.h,result.proj3.p,result.proj3.ci,result.proj3.stats] = ttest2(loadings(1:numel(sample1),2),loadings(numel(sample1)+1:end,2));
                
                result.proj1.vector = Vector3D(main_axis).unit;
                result.proj2.vector = Vector3D(directions(:,1));
                result.proj3.vector = Vector3D(directions(:,2));
                
                disp(['proj1 --> p= ',num2str(result.proj1.p)])
                disp(['proj2 --> p= ',num2str(result.proj2.p)])
                disp(['proj3 --> p= ',num2str(result.proj3.p)])

                disp('"PC_stats" is saved to the workspace')
                assignin('base','PC_stats',result)
                 
                %draw vector in scene for all significant directions
                basevector = Vector3D(mean(allData));
                fields = fieldnames(result);
                colorcounter = 1;
                for iField = 1:numel(fields)
                    if result.(fields{iField}).p < 0.05
                        vc_actor = VectorCloud(basevector,result.(fields{iField}).vector).see(scene);
                        vc_actor.changeName([fields{iField},' p=',num2str(result.(fields{iField}).p), '  ',mat2str(round(result.(fields{iField}).vector.getArray,2))])
                        vc_actor.changeSetting('color1',scene.colorTheme{colorcounter})
                        colorcounter = colorcounter+1;
                    end
                end
                
                
                
            end
            
            
            function menu_mergePointCloud(hObject,eventdata)
                %make new empty pointcloud to collect others
                newPC = PointCloud();
                scene = ArenaScene.getscenedata(hObject);
                currentActors = ArenaScene.getSelectedActors(scene);
                
                for iActor = 1:numel(currentActors)
                    thisActor = currentActors(iActor);
                    newPC = newPC.addVectors(thisActor.Data);
                end
                newPC.see(scene)
                
            end
            
            function menu_pcDistribution(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                currentActors = ArenaScene.getSelectedActors(scene);
                
                for iActor = 1:numel(currentActors)
                    thisActor = currentActors(iActor);
                    switch class(thisActor.Data)
                        case 'PointCloud'
                            
                            %--cog
                            thisActor.Data.getCOG;
                            cog_actor = PointCloud(thisActor.Data.getCOG).see(scene);
                            cog_actor.changeSetting('colorLow', thisActor.Visualisation.settings.colorLow,'thickness',500);
                            cog_actor.changeName(['middle of ',cog_actor.Tag]);
                            
                           %--distribution
                           
                           
                           std_ = Vector3D(std(thisActor.Data.Vectors.getArray));
                            [ex,ey,ez] = ellipsoid(thisActor.Data.getCOG.x,...
                                thisActor.Data.getCOG.y,...
                                thisActor.Data.getCOG.z,...
                                std_.x,...
                                std_.y,...
                                std_.z,...
                                30);

                            temp = surf(ex,ey,ez);
                            temp2 = surf2patch(temp);
                            delete(temp);

                            dist = Mesh(temp2.faces,temp2.vertices).see(scene);
                            dist.changeSetting('colorFace',thisActor.Visualisation.settings.colorLow,'faceOpacity',20);
                            dist.changeName(['spread (1 std) of ',cog_actor.Tag]);
                            
                            disp('---')
                            disp(['COG of ',thisActor.Tag])
                            disp(thisActor.Data.getCOG)
                            
                            disp(['1 std of ',thisActor.Tag])
                            disp(std_)
                            
                           
                           
                        otherwise
                            disp([thisActor.Tag,' is not a pointcloud but a ',class(thisActor.Data)])
                           
                    end
                end
                
                
            end
            
            function menu_fwhm(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                currentActors = ArenaScene.getSelectedActors(scene);
                dataCell = {};
                for iActor = 1:numel(currentActors)
                        thisActor = currentActors(iActor);
                        switch class(thisActor.Data)
                            case 'Mesh'
                                if not(isempty(thisActor.Data.Source))
                                    [data,fhandle] = thisActor.Data.Source.getDensityDistribution;
                                     dataCell{iActor} = data;
                                     title([thisActor.Tag,' {\color{red} x:',num2str(data.x),'\color{green}  y:',num2str(data.y),'\color{blue} z:',num2str(data.z),'}'])
                                     disp('-----')
                                     disp(thisActor.Tag)
                                     disp('-----')
                                     disp('>> FWHM')
                                     disp(data)
                                     disp('>> COG')
                                    disp(thisActor.Data.Source.getcog)
                                end
                        end
                end
                
                if iActor>1
                    %define the x-data
                    fields = {'xCi','yCi','zCi';'xVi','yVi','zVi'};
                    titles = {'X','Y','Z'};
                    for dimension = 1:3
                        
                        f = figure;
                        title(titles{dimension})
                        set(f,'DefaultLineLineWidth',2)
                        hold on;
                        xcell = {};
                        ycell = {};
                        
                        min_x = [];
                        max_x = [];
                        for iD = 1:numel(dataCell)
                            thisData = dataCell{iD};
                            x = thisData.(fields{1,dimension});
                            y = thisData.(fields{2,dimension});
                            y = y/max(y);
                            p = plot(x,y,'Color',currentActors(iD).Visualisation.settings.colorFace);
                            
                            
                            xcell{iD} = x;
                            ycell{iD} = y;
                            
                            min_x(end+1) = xcell{iD}(find(ycell{iD}>0,1,'first'));
                            max_x(end+1) = xcell{iD}(find(ycell{iD}>0,1,'last'));
                        end
                        
                         %find the xlim (to only include data >0)
                         
            minCoord = min(min_x);
           
           maxCoord = max(max_x);
           
           xlim([minCoord,maxCoord])

                        legend({currentActors(:).Tag}, 'Interpreter', 'none')
                        
                    end
                end
                    
            end
            
            function output = menu_sampleHeatmap(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                currentActors = ArenaScene.getSelectedActors(scene);
                
                %show popup to select ROIs
                labels = {scene.Actors.Tag};
                [indx,tf] = listdlg('PromptString',{'Select one or more ROIs'},'ListString',labels);
                
                if tf==0
                    %user canceled
                    return
                end
                
                ROIlist = [];
                for iROI = indx
                    thisROI = scene.Actors(iROI);
                    switch class(thisROI.Data)
                        case 'Mesh'
                            ROI_vd = thisROI.Data.Source.makeBinary(thisROI.Data.Settings.T);
                            ROIlist(end+1).name = thisROI.Tag;
                            ROIlist(end).vd = ROI_vd;
                        otherwise
                            warning('Code can be extended to support other kinds of data. But at the moment only meshes are allowed.')
                            continue
                    end
                end
                
                output = [];
                %each actor is supposed to be a heatmap, or some voxel data
                %that should be sampled
                for iHeatmap = 1:numel(currentActors)
                    thisHeatmap = currentActors(iHeatmap);
                    if not(isa(thisHeatmap.Data,'Mesh'))
                        warning('Make sure the heatmap is imported as  mesh. This can be extended in the future but currently suffices')
                        continue
                    end
                      
                    heatmap_vd = thisHeatmap.Data.Source;
                    
                    for iROI = 1:numel(ROIlist)
                        ROI_vd = ROIlist(iROI).vd;
                        warped_ROI = ROI_vd.warpto(heatmap_vd);
                        VoxelSelection = heatmap_vd.Voxels(warped_ROI.Voxels);
                        
                        output(end+1).heatmap = thisHeatmap.Tag;
                        output(end).ROI = ROIlist(iROI).name;
                        output(end).Voxels = VoxelSelection;
                        output(end).mean = nanmean(output(end).Voxels(:));
                        output(end).max = nanmax(output(end).Voxels(:));
                        output(end).min = nanmin(output(end).Voxels(:));
                    end

                end
                
                assignin('base','ROIresult',output)
                disp('variable "ROIresult" is now available in your workspace')
                
                
            end
            
            function menu_showFibers(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                currentActors = ArenaScene.getSelectedActors(scene);
                
                if length(currentActors)~= 1
                    N_FIBERS_cell = newid({'number of fibers visualised: '},'Arena Fibers',1,{'10'});
                    N_FIBERS = N_FIBERS_cell{1};
                    home;
                    disp('Running batch operation.')
                    disp('-----------------------')
                else
                    N_FIBERS = 100;
                end
                
                global connectomes
                    if not(isa(connectomes,'ConnectomeManager'))
                        connectomes = ConnectomeManager;
                    end
                thisConnectome = connectomes.selectConnectome;
                
                for iActor = 1:numel(currentActors)
                    home;
                    thisActor = currentActors(iActor);
                    thisFiber = thisConnectome.getFibersPassingThroughMesh(thisActor.Data,N_FIBERS,scene);
                    thisFiber.ActorHandle.changeSetting('colorByDirection',0,'colorFace',thisActor.Visualisation.settings.colorFace,'numberOfFibers',N_FIBERS);
                    thisFiber.ActorHandle.changeName([thisActor.Tag,'_fiber']);
                end
               
            end
            
            
            function menu_showFibers_inbetween(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                currentActors = ArenaScene.getSelectedActors(scene);
                
                if length(currentActors)~= 2
                    return
                end
                
                global connectomes
                    if not(isa(connectomes,'ConnectomeManager'))
                        connectomes = ConnectomeManager;
                    end
                thisConnectome = connectomes.selectConnectome;
                
                Fibers = thisConnectome.getFibersConnectingMeshes({currentActors(1).Data,currentActors(2).Data},100,scene);
                
                
            end
            
            function menu_seperateClusters(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                currentActors = ArenaScene.getSelectedActors(scene);
                
                    for iActor = 1:numel(currentActors)
                        thisActor = currentActors(iActor);
                        switch class(thisActor.Data)
                            case 'Mesh'
                                binaryVoxelData = thisActor.Data.Source.makeBinary(thisActor.Visualisation.settings.threshold);
                                [regions,labeled,sizelist] = binaryVoxelData.seperateROI();
                                [sorted,order] = sort(sizelist,'descend');
                                if numel(sizelist)>6
                                    a1 = numel(sizelist)
                                    prompt = {sprintf('The selected Mesh has %d clusters.\n\nPlease specify how many should be displayed:\n(biggest will be displayed first)',a1)};
                                    dlgtitle = 'Specify number of clusters';
                                    dims = [1 55];
                                    a2 = inputdlg(prompt,dlgtitle,dims);
                                    ncluster = str2num(a2{1});
                                else
                                    ncluster = numel(sizelist);
                                end
                                for iCluster = 2:ncluster
                                    actor = regions{order(iCluster)}.getmesh(0.5).see(scene);
                                    actor.changeName([num2str(sorted(iCluster)),'_',thisActor.Tag])
                                end
                                
                                
                                
                                
                                
                                
                               
                        end
                    end
                
            end
            
            function menu_smoothVoxelData(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                    currentActors = ArenaScene.getSelectedActors(scene);
                    
                    for iActor = 1:numel(currentActors)
                        thisActor = currentActors(iActor);
                        switch class(thisActor.Data)
                            case 'Mesh'
                                thisActor.Data.Source.smooth();
                                %change the threshold so that it
                                %redraws the shape using the new data:
                                
                                settings = getsettings(scene);
                                oldSetting = thisActor.Visualisation.settings.threshold;
                                
                                settings.threshold = Inf; %should not render a mesh.
                                thisActor.updateActor(scene,settings);
                                
                                settings.threshold = oldSetting;
                                thisActor.updateActor(scene,settings);
                        end
                    end
            end
            
            
            function menu_dice(hObject,eventdata)
                 scene = ArenaScene.getscenedata(hObject);
                    currentActors = ArenaScene.getSelectedActors(scene);
                    
                    %get binary data
                    inputdata = VoxelData.empty;
                    labels = {};
                    for iActor = 1:numel(currentActors)
                        thisActor = currentActors(iActor);
                        switch class(thisActor.Data)
                            case 'Mesh'
                                if not(isempty(thisActor.Data.Source))
                                    vd = thisActor.Data.Source;
                                    vd_bin = vd.makeBinary(thisActor.Data.Settings.T);
                                    inputdata(end+1) = vd_bin;
                                    labels{end+1} = thisActor.Tag;
                                end
                        end
                    end
                    
                    %run dice
                    a = [];
                    for x = 1:numel(inputdata)
                        for y = 1:numel(inputdata)
                           w = inputdata(y).warpto(inputdata(x));
                           a(x,y) = dice(w,inputdata(x));
                        end
                    end
                    %check if the labels are valid
                    [labels,~] = A_validname(labels);
                    
                    %show results
                    similarity = array2table(a,'RowNames',labels,'VariableNames',labels)
                   assignin('base','similarity',similarity); 
                   disp('saved in workspace as >> similarity')
                    
            end
            
            function menu_intersectPlane(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                currentActors = ArenaScene.getSelectedActors(scene);
                
                if numel(currentActors)>1
                    warning('Select 1 actor for intersection')
                    return
                end
                if not(isa(currentActors.Data,'Slicei'))
                    warning('actor needs to be a slice')
                    return
                end
                
                %get meshes and pointclouds
                allActors = scene.Actors;
                meshes = [];
                pointclouds = [];
                for iActor = 1:numel(allActors)
                    thisActor = allActors(iActor);
                    if or(isa(thisActor.Data,'Mesh'),isa(thisActor.Data,'ObjFile'))
                        meshes(end+1).name = thisActor.Tag;
                        meshes(end).actor = thisActor;
                    end
                    if isa(thisActor.Data,'PointCloud')
                        pointclouds(end+1).name = thisActor.Tag;
                        pointclouds(end).actor = thisActor;
                    end
                end
                
                if not(isempty(meshes))
                    [indx,tf] = listdlg('PromptString','Select meshes to project','ListString',{meshes.name});
                    if tf==0
                       % disp('user aborted')
                        indx = [];
                    end
                else
                    indx = [];
                end
                
                %define plane

                switch currentActors.Visualisation.settings.plane
                    case 'axial'
                        planes.n = [0 0 1];
                        planes.r = planes.n*currentActors.Visualisation.settings.slice;
                    case 'coronal'
                        planes.n = [0 1 0];
                        planes.r = planes.n*currentActors.Visualisation.settings.slice;
                    case 'sagittal'
                        planes.n = [1 0 0];
                        planes.r = planes.n*currentActors.Visualisation.settings.slice;
                end
  
                
                %get polygons
                for iProj = indx
                    thisProj = meshes(iProj).actor.Data;
                    polygons = mesh_xsections( thisProj.Vertices, thisProj.Faces, planes, [], 0 );
                    
                    
                    %draw polygons
                    for s = 1 : numel( polygons )
                        if ~isempty( polygons{ s } )
                            for p = 1 : numel( polygons{ s } )
                                
                                switch currentActors.Visualisation.settings.plane
                                    case 'axial' 
                                        thispatch = patch( polygons{ s }{ p }( :, 1 ), ...
                                       polygons{ s }{ p }( :, 2 ),...
                                        polygons{ s }{ p }( :, 3 ));
                                        thispatch.ZData = ones(size(thispatch.XData))*currentActors.Visualisation.settings.slice;
                                    case 'coronal'
                                        %patches are 2d. So pretend to
                                        %project it axially first, and then
                                        %flip it coronal
                                        thispatch = patch( polygons{ s }{ p }( :, 1 ), ...
                                       polygons{ s }{ p }( :, 3 ),...
                                        polygons{ s }{ p }( :, 2 ));
                                        thispatch.ZData = thispatch.YData;
                                        thispatch.YData = ones(size(thispatch.XData))*currentActors.Visualisation.settings.slice;
                                    
                                    case 'sagittal'
                                      thispatch = patch( polygons{ s }{ p }( :, 3 ), ...
                                       polygons{ s }{ p }( :, 2 ),...
                                        polygons{ s }{ p }( :, 1 ));
                                        thispatch.ZData = thispatch.XData;
                                        thispatch.XData = ones(size(thispatch.XData))*currentActors.Visualisation.settings.slice;
                                    
                                end
                                
                                newObj = Contour(thispatch);
                                newActor = newObj.see(scene);
                                newActor.changeName(['slice of ',meshes(iProj).name])
                                newActor.changeSetting('colorFace',meshes(iProj).actor.Visualisation.settings.colorFace,...
                                    'colorEdge',meshes(iProj).actor.Visualisation.settings.colorEdge);
                                
                            end
                        end
                    end
                end
                
                if not(isempty(pointclouds))
                    [indx,tf] = listdlg('PromptString','Select Pointclouds to project','ListString',{pointclouds.name});
                    if tf==0
                        disp('user aborted')
                        return
                    end
                else
                    indx = [];
                end
                
                for iPC = indx
                    pc_source = pointclouds(iPC).actor.Data;
                    data = pc_source.Vectors.getArray;
                    switch currentActors.Visualisation.settings.plane
                        case 'axial' 
                            data(:,3) = ones(size(data(:,3)))*currentActors.Visualisation.settings.slice;
                        case 'coronal'
                            data(:,2) = ones(size(data(:,2)))*currentActors.Visualisation.settings.slice;
                        case 'sagittal'
                            data(:,1) = ones(size(data(:,1)))*currentActors.Visualisation.settings.slice;
                    end
                    newPC = PointCloud(data,pc_source.Weights);
                    newActor = newPC.see(scene);
                    newActor.changeSetting('colorLow',pointclouds(iPC).actor.Visualisation.settings.colorLow);
                    newActor.changeSetting('colorHigh',pointclouds(iPC).actor.Visualisation.settings.colorHigh);
                    newActor.changeSetting('thickness',pointclouds(iPC).actor.Visualisation.settings.thickness);
                    newActor.changeSetting('opacity',pointclouds(iPC).actor.Visualisation.settings.opacity);
                    newActor.changeName([currentActors.Visualisation.settings.plane,' ',pointclouds(iPC).actor.Tag]);
                    
                end
                
            end
            
                
            
            function menu_getinfo(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                currentActors = scene.Actors; %all Actors.
                
               name = {};
               actorType = {};
               nVoxels = [];
               voxelsize = [];
               cubicMM = [];
               minVoxelvalue = [];
               maxVoxelvalue = [];
                
               for iActor = 1:numel(currentActors)
                thisActor = currentActors(iActor);
                name{iActor,1} = thisActor.Tag;
                actorType{iActor,1} = class(thisActor.Data);
                switch class(thisActor.Data)
                    case 'Mesh'
                        if isempty(thisActor.Data.Source)
                            %msgbox('This mesh is not based on VoxelData, pleas ask Jonas for help') %perhaps voxelise?
                            nVoxels(iActor,1) = nan;
                            voxelsize(iActor,1) = nan;
                            cubicMM(iActor,1) = nan;
                            minVoxelvalue(iActor,1) = nan;
                            maxVoxelvalue(iActor,1) = nan;
                        else
                            [cubicmm,voxelcount] = thisActor.Data.Source.getCubicMM(thisActor.Data.Settings.T);
                            
                            nVoxels(iActor,1) = voxelcount;
                            voxelsize(iActor,1) = thisActor.Data.Source.R.PixelExtentInWorldX*thisActor.Data.Source.R.PixelExtentInWorldY*thisActor.Data.Source.R.PixelExtentInWorldZ;
                            cubicMM(iActor,1) = cubicmm;
                            minVoxelvalue(iActor,1) = nanmin(thisActor.Data.Source.Voxels(:));
                            maxVoxelvalue(iActor,1) = nanmax(thisActor.Data.Source.Voxels(:));
                        end
                end
               end
               info = table(name,actorType,nVoxels,voxelsize,cubicMM,minVoxelvalue,maxVoxelvalue)
                assignin('base','info',info);
                    
                
            end
            
            function menu_edit_add2mesh(hObject,eventdata)
                warning('does not exist yet')
            end
            
            function menu_edit_add2plane(hObject,eventdata)
                warning('does not exist yet')
            end
            
            
            
            
            function btn_updateActor(hObject,eventdata)
                
                scene = hObject.Parent.Parent.UserData;
                actorList = scene.Actors;
                thisActor = actorList(scene.handles.panelright.Value);
                settings = getsettings(scene);
                
                settings = ArenaScene.ignoreUnchangedSettings(settings,thisActor(1));
                
                for i = 1:numel(thisActor)
                    thisActor(i).updateActor(scene,settings)
                end
                
                scene.refreshLayers()
            end
            
            function btn_layeroptions(hObject,eventdata)
                scene = hObject.Parent.UserData;
                actorList = scene.Actors;
                thisActor = actorList(scene.handles.panelright.Value);
                if numel(thisActor)==1
                    thisActor.edit(scene);
                else
                    answer = questdlg('What''s up?','Arena','add name prefix','delete selection','cancel','cancel');
                    switch answer
                        case 'add name prefix'
                            newname = inputdlg('Change prefix','Arena',[1 40],{''});
                            for iActor = 1:numel(thisActor)
                                thisOne = thisActor(iActor);
                                thisOne.Tag = [newname{1},thisOne.Tag];
                            end
                            scene.refreshLayers();
                        case 'delete selection'
                            rusure = questdlg(['You are about to delete some actors for eternity.'],'Arena','delete','cancel','cancel');
                            switch rusure
                                case 'delete'
                                    for iActor = 1:numel(thisActor)
                                        thisOne = thisActor(iActor);
                                        delete(thisOne,scene)
                                    end
                                    scene.refreshLayers();
                                case 'cancel'
                                    return
                            end
                    
                    end
                end
            end
                
            function panelright_callback(hObject,~)
                scene = hObject.Parent.UserData;
                currentActor = scene.Actors(hObject.Value);
                
                %see of all selected actors are of the same class
                firstActor = class(currentActor(1).Data);
                consistentclass = [true];
                for iActor = 1:numel(currentActor)
                    consistentclass(iActor) = strcmp(firstActor,class(currentActor(iActor).Data));
                end
                
                
                    hObject.Value = hObject.Value(consistentclass);
              
                
                currentActor(1).updateCC(scene);
                scene.updateMenu()
                
            end
            
            function settings = getsettings(scene)
                settings = [];
                for i = 1:numel(scene.handles.configcontrols)
                    h = get(scene.handles.configcontrols(i));
                    switch h.Style
                        case 'text'
                            continue
                        case 'pushbutton'
                            if contains(h.Tag,'color')
                                settings.(h.Tag) = h.BackgroundColor;
                            end
                        case 'edit'
                            settings.(h.Tag) = str2num(h.String);
                            if isempty(settings.(h.Tag))
                                settings.(h.Tag) = NaN;
                            end
                        case 'checkbox'
                            settings.(h.Tag) = h.Value;
                        case 'popupmenu'
                            settings.(h.Tag) = h.String{h.Value};
                        otherwise
                            keyboard
                    end
                    
                end
                
            end
            
            
            function keyShortCut(src,eventdata)
                
                
                switch eventdata.EventName
                    case 'WindowMousePress'
                        %disp('click')
                    otherwise
                        scene = ArenaScene.getscenedata(src);
                %disp(eventdata.Key)
                f = scene.handles.figure;
                f.WindowButtonMotionFcn = @setcurrentpointlive;
                pt = getcurrentpoint(f);
                clearPreviousContextMenus()

                switch eventdata.Key
                    case 'uparrow'
                        original_pos = campos;
                        original_target = camtarget;
                        viewline = original_pos - original_target;
                        campos(original_target + viewline * 0.9);
                    case 'downarrow'
                        original_pos = campos;
                        original_target = camtarget;
                        viewline = original_pos - original_target;
                        campos(original_target + viewline / 0.9);
                        
                    case 's'
                        if numel(eventdata.Modifier)>2
                            show_shortcuts(src);
                        end
                    case 'i'
                        if ~isempty(eventdata.Modifier)
                        switch eventdata.Modifier{1}
                            case {'command','shift'}
                                menu_importAnything(src)
                        end
                        end
                        
                    case 'o'
                         menu_camTargetOrigin(src,eventdata)
                    
                    case '1'
                        if ~isempty(eventdata.Modifier)
                        switch eventdata.Modifier{1}
                            case 'shift'
                                input.Text = 'axial plane';
                                 menu_orthogonal(input)
                            case 'command'
                                if numel(scene.handles.menu.view.camera.multi.cam)>=1
                                    hObject.Text = '1';
                                    hObject.UserData = scene;
                                    menu_camera_switch(hObject)
                                end
                        end
                        end
                    case '2'
                        if ~isempty(eventdata.Modifier)
                        switch eventdata.Modifier{1}
                            case 'shift'
                            input.Text = 'sagittal plane';
                            menu_orthogonal(input)
                            case 'command'
                                if numel(scene.handles.menu.view.camera.multi.cam)>=1
                                    hObject.Text = '2';
                                    hObject.UserData = scene;
                                    menu_camera_switch(hObject)
                                end
                        end
                        end
                    case '3'
                        if ~isempty(eventdata.Modifier)
                        switch eventdata.Modifier{1}
                            case 'shift'
                                input.Text = 'coronal plane';
                                menu_orthogonal(input)
                                case 'command'
                                if numel(scene.handles.menu.view.camera.multi.cam)>=1
                                    hObject.Text = '3';
                                    hObject.UserData = scene;
                                    menu_camera_switch(hObject)
                                end
                        end
                        
                        end
                    case 'period'
                            
                           if numel(ArenaScene.getSelectedActors(scene))==1
                            menu_camTargetActor(src,eventdata)
                 
                           end
                    case 'x'
                         scene.handles.contextmenu = uicontrol('style','togglebutton',...
                            'units','pixels',...
                                 'position', [pt(1),pt(2),60,30],...
                            'String','delete',...
                            'Value',1,...
                            'callback',{@context_deleteActor},...
                            'Tag','context');

                             f.WindowButtonMotionFcn = {@contextMenuBehaviour,pt};
                    case 'a'
                        if not(isempty(eventdata.Modifier))
                            switch eventdata.Modifier{1}
                                case 'shift'
                                    scene.handles.contextmenu = uicontrol('style','togglebutton',...
                                'units','pixels',...
                                     'position', [pt(1),pt(2),60,30],...
                                'String','add actor',...
                                'Value',1,...
                                'callback',{@context_import},...
                                'Tag','context');  

                                    f.WindowButtonMotionFcn = {@contextMenuBehaviour,pt};
                                otherwise
                                    return
                            end
                        end
                        
                    case 'h' %hide
                        
                        if not(isempty(eventdata.Modifier))
                         switch eventdata.Modifier{1}
                            case 'shift'
                                hideLayers(src,'solo')
                             case 'alt'
                                 hideLayers(src,'unhide')
                         end
                        else
                            hideLayers(src,'toggle')
                         end
                        
                        
                        
                end
                end
                
                function clearPreviousContextMenus()
                    if isfield(scene.handles,'contextmenu')
                        if not(isempty(scene.handles.contextmenu))
                            delete(scene.handles.contextmenu)
                        end
                    end
                end

                function pt = getcurrentpoint(f)
                    
                        currpt = get(f,'CurrentPoint');
                        try
                            pt = matlab.graphics.interaction.internal.getPointInPixels(f,currpt(1:2));
                        catch % old matlab version
                            pt = currpt;
                        end
                end
                
                
                function contextMenuBehaviour(fig,event,xy)
                   
                    pt2 = getcurrentpoint(f);
                    distnc = norm(pt2-xy);
                    if distnc > 200
                        scene.handles.contextmenu.Visible =  'off';
                        f.WindowButtonMotionFcn = @setcurrentpointlive;
                
                    end
                    
                end
                
                function flash(text,f)
                    t = uicontrol(f,'Style','text',...
                        'String','Select a data set.',...
                        'Position',[30 50 130 30]);
                    t.String = text;
                    t.BackgroundColor = f.Color;
                    t.ForegroundColor = 1-t.BackgroundColor;
                    t.FontSize = 20;
                    t.Units = 'normalized';
                    t.Position = [0.4,0.8,0.2,0.05];
                    pause(2)
                    delete(t)
                end
            end
            
            function show_shortcuts(src)
                msgbox('Something like this Hazem?')
            end
        
            function hideLayers(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                [currentActors,iSelected] = ArenaScene.getSelectedActors(scene);
                
                switch eventdata
                    case 'toggle'
                        for iActor = 1:numel(currentActors)
                            thisActor = currentActors(iActor);
                            thisActor.Visibility('toggle');
                        end
                    case 'unhide'
                        for iActor = 1:numel(scene.Actors)
                            thisActor = scene.Actors(iActor);
                            thisActor.Visibility('unhide');
                        end
                    case 'solo'
                        for iActor = 1:numel(scene.Actors)
                            thisActor = scene.Actors(iActor);
                            if any(find(iSelected==iActor))
                                thisActor.Visibility('unhide')
                            else
                                thisActor.Visibility('hide');
                            end
                        end
                end
                scene.refreshLayers();
                
            end
            
                function setcurrentpointlive(fig,event)
                    %this nothing, but its presence is enough. :-) trust me
                
                end
            function context_deleteActor(hObject,eventdata)
               scene = ArenaScene.getscenedata(hObject);
                currentActors = ArenaScene.getSelectedActors(scene);
                
                if numel(currentActors)>1
                    answer = questdlg(['You are about to delete all ',num2str(numel(currentActors)),' actors, do you wish to proceed?'],'Hold on..','Yes, delete them!','go back','delete!');
                    switch answer
                        case 'Yes, delete them!'
                            for i = 1:numel(currentActors)
                                delete(currentActors(i),scene)
                            end
                    end
                
                else
                    delete(currentActors,scene)
                end
                
                scene.handles.contextmenu.Visible = 'off';
                scene.refreshLayers();
            end
        
            function context_import(hObject,eventdata)
                menu_importAnything(hObject)
            end
            
            function closeScene(src, callbackdata)
                %Close request function
                selection = questdlg('Close This Figure?',...
                    'Close Request Function',...
                    'Yes','No','Yes');
                switch selection
                    case 'Yes'
                        global arena
                        try
                            %delete suretuneportals when still open
                            for iPortal = 1:numel(src.UserData.handles.menu.stusessions.openwindows)
                                delete(src.UserData.handles.menu.stusessions.openwindows{iPortal}.UserData.handles.f)
                            end
                            %delete from manager
                            deleteIndex = find(arena.Scenes==src.UserData);
                            arena.Scenes(deleteIndex) = [];
                            
                            %close window
                            delete(gcf)

                        catch
                            delete(gcf)
                            warning('Scene was an orphan..')
                        end
                        
                    case 'No'
                        return
                end
            end
            %--------------------------------------------------------------
            function menu_selectActorPrediction(hObject,eventdata)
                thisScene=ArenaScene.getscenedata(hObject);
                thisScene.handles.menu.file.predict.close.Enable='on';
                thisScene.handles.menu.file.predict.results.Enable='on'; %submenu on
                if isempty(thisScene.Actors)
                    thisScene.handles.box_listSelectActor.String='Prediction without using the "until now" imported data.';
                else
                    actorNames=[];
                    actorNames(1,1).Tag='Prediction without using the "until now" imported data.';
                    actorNames(1,1).Number=[];
                    for i=1:numel(thisScene.Actors(1, 1:end))
                        if strcmp(thisScene.Actors(1,i).Tag(1:4),'Lead')
                            actorNames(1,end+1).Tag=thisScene.Actors(1,i).Tag;
                            actorNames(1,end).Number=i;
                        else
                        end
                    end
                    thisScene.handles.box_listSelectActor.UserData=struct();
                    thisScene.handles.box_listSelectActor.UserData=actorNames;
                    thisScene.handles.box_listSelectActor.String={actorNames(1,1:end).Tag};
                end
                thisScene.handles.box_listSelectActor.Visible='on';
                thisScene.handles.text_box_listSelectActor.Visible='on';
            end
            
            function box_listSelectActor(hObject,eventdata)
                thisScene=ArenaScene.getscenedata(hObject);
                selection=thisScene.handles.box_listSelectActor.Value;
                if selection==1
                    PathDirectory=0;
                    thisScene.Actors(1,1).PredictInformation=predictFuture();
                    thisScene.Actors(1,1).PredictInformation.newPrediction(PathDirectory);
                    try
                        waitfor(thisScene.Actors(1,1).PredictInformation.handles.figure);
                    catch
                        return
                    end
                    try
                        if isempty(thisScene.Actors(1,1).PredictInformation.Heatmap)
                            warning('No Prediction Data was calculated!');
                        end
                    catch
                        return
                    end
                    warning('You did a Prediction which you can not be found in your current Actor list! When you do one more it gets overwritten!');
                    thisScene.Actors=[];
                    thisScene.Actors=ArenaActor.empty();
                elseif selection>1
                    selection=thisScene.handles.box_listSelectActor.UserData(1,selection).Number;
                    PathDirectory=thisScene.Actors(1,selection).PathDirectory;
                    thisScene.Actors(1,selection).PredictInformation=predictFuture();
                    thisScene.Actors(1,selection).PredictInformation.Tag=thisScene.Actors(1,selection).Tag;
                    thisScene.Actors(1,selection).PredictInformation.newPrediction(PathDirectory);
                    try
                        waitfor(thisScene.Actors(1,selection).PredictInformation.handles.figure);
                    catch
                        return
                    end
                    try
                        if isempty(thisScene.Actors(1,selection).PredictInformation.Heatmap)
                            warning('No Prediction Data was calculated!');
                        else
                            thisScene.Actors(1,selection).PredictInformation={thisScene.Actors(1,selection).PredictInformation.handles.prediction_Information,thisScene.Actors(1,selection).PredictInformation.Heatmap,...
                                thisScene.Actors(1,selection).PredictInformation.config};
                        end
                    catch
                        return
                    end
                end
                answer=questdlg('Do you want to try a prediction for a other lead?','Decision','Yes','No','No');
                if strcmp(answer,'No')
                    thisScene.handles.box_listSelectActor.Visible='off';
                    thisScene.handles.text_box_listSelectActor.Visible='off';
                    thisScene.handles.box_listSelectActor.String=[];
                    thisScene.handles.menu.file.predict.close.Enable='off';
                end
                try
                    if isa(thisScene.Actors(1,selection).PredictInformation,'cell')
                        answer=questdlg('Would you like to display your Results?','Decision','Yes','No','No');
                        if strcmp(answer,'Yes')
                            thisScene.handles.box_listSelectResult.Visible='on';
                            thisScene.handles.text_box_listSelectResult.Visible ='on';
                            listSelectResultEnd=numel(thisScene.handles.box_listSelectActor.String);
                            thisScene.handles.box_listSelectResult.String={};
                            for irepetitions=2:listSelectResultEnd
                                actorNumber=thisScene.handles.box_listSelectActor.UserData(1,irepetitions).Number;
                                try
                                    if isa(thisScene.Actors(1,actorNumber).PredictInformation,'cell')
                                        elementsOfString=numel(thisScene.handles.box_listSelectResult.String);
                                        if elementsOfString==0
                                            elementsOfString=1;
                                        else
                                            elementsOfString=elementsOfString+1;
                                        end
                                        thisScene.handles.box_listSelectResult.String{elementsOfString}=thisScene.Actors(1,actorNumber).Tag;
                                        thisScene.handles.box_listSelectResult.UserData(1,elementsOfString).Number=actorNumber;
                                        
                                    end
                                catch
                                    return;
                                end
                            end
                        end
                    end
                end
            end
                            
            function menu_viewActorResults(hObject,eventdata)
                thisScene=ArenaScene.getscenedata(hObject);
                thisScene.handles.text_box_listSelectResult.Visible ='on';
                thisScene.handles.box_listSelectResult.Visible='on';
                thisScene.handles.menu.file.predict.close.Enable='on';
                listSelectResultEnd=numel(thisScene.handles.box_listSelectActor.String);
                thisScene.handles.box_listSelectResult.String={};
                thisScene.handles.box_listSelectResult.UserData=struct();
                for irepetitions=2:listSelectResultEnd
                    actorNumber=thisScene.handles.box_listSelectActor.UserData(1,irepetitions).Number;
                    try
                        if isa(thisScene.Actors(1,actorNumber).PredictInformation,'cell')
                            elementsOfString=numel(thisScene.handles.box_listSelectResult.String);
                            if elementsOfString==0
                                elementsOfString=1;
                            else
                                elementsOfString=elementsOfString+1;
                            end
                            thisScene.handles.box_listSelectResult.String{elementsOfString}=thisScene.Actors(1,actorNumber).Tag;
                            thisScene.handles.box_listSelectResult.UserData(1,elementsOfString).Number=actorNumber;
                        end
                    catch
                    end
                end
            end
            
            function box_listSelectResult(hObject,eventdata)
                thisScene=ArenaScene.getscenedata(hObject);
                displayDecision=thisScene.handles.box_listSelectResult.Value;
                displayDecision=thisScene.handles.box_listSelectResult.UserData(1,displayDecision).Number;
                if not(isempty(displayDecision))
                    d=predictResults();
                    d.displayHighestResults(thisScene.Actors(1,displayDecision));
                    answer=questdlg('Would you like to display other Results?','Decision','Yes','No','No');
                    if strcmp(answer,'No')
                        thisScene.handles.box_listSelectResult.Visible='off';
                        thisScene.handles.text_box_listSelectResult.Visible='off';
                    end
                else
                    error('No Prediction Data was found!');
                end
            end
            
            function menu_closePredictionWindows(hObject,eventdata)
                thisScene=ArenaScene.getscenedata(hObject);
                thisScene.handles.menu.file.predict.results.Enable='off';
                thisScene.handles.text_box_listSelectActor.Visible='off';
                thisScene.handles.box_listSelectActor.Visible='off';
                thisScene.handles.text_box_listSelectResult.Visible='off';
                thisScene.handles.box_listSelectResult.Visible='off';
                thisScene.handles.menu.file.predict.close.Enable='off';
            end
            
            function menu_showOldResults(hObject,eventdata)
                waitfor(msgbox('Please select your old Results from other Prediction!'));
                [file,pathDirectory]=uigetfile('*.mat','Select old Results');
                result=load(fullfile(pathDirectory,file));
                d=predictResults();
                d.displayHighestResults(result);
                msgbox('Your Result is shown!')
            end
            
            %--------------------------------------------------------------
    end
        
        function thisActor = newActor(obj,data,OPTIONALvisualisation)
            thisActor = ArenaActor;
            
            if nargin==3 %when reviving an actor in a new scene.
                thisActor.create(data,obj,OPTIONALvisualisation)
            else
                thisActor.create(data,obj)
            end
            obj.Actors(end+1) = thisActor;
           refreshLayers(obj); 
            selectlayer(obj,'last')
            
        end
        
        function refreshLayers(obj)
            %colors
            pre = '<HTML><FONT color="';
            mid = '</FONT>';
            post = '</HTML>';

            
            ActorTags = {};
            for i = 1:numel(obj.Actors)
                properties = fieldnames(obj.Actors(i).Visualisation.settings);
                rgbColour = obj.Actors(i).Visualisation.settings.(properties{1})*255;
              hexStr = reshape( dec2hex( round(rgbColour), 2 )',1, 6);
                
                if obj.Actors(i).Visible
                    bubble = '&#11044;';
                else
                    bubble ='&#9711;';
                end
                str = [pre, hexStr, '">', bubble,' ',mid, obj.Actors(i).Tag, post];
                ActorTags{i} = str;
            end
            obj.handles.panelright.String = ActorTags;
            
            if obj.handles.panelright.Value > numel(obj.handles.panelright.String)
                obj.handles.panelright.Value = 1;
            end
            
            obj.selectlayer()
            obj.updateMenu()
            drawnow()
            

          
        end
        
        
        
        function updateMenu(obj)
            try
            thisclass = class(obj.Actors(obj.handles.panelright.Value(1)).Data);
            catch
                obj.handles.menu.dynamic.main.Text = '...';
                return %no layers 
            end
            obj.handles.menu.dynamic.main.Text = ['--> ',thisclass];
            
            otherclasses = fieldnames(obj.handles.menu.dynamic);
            for iOther = 1:numel(otherclasses)
                thisOtherClass = otherclasses{iOther};
                switch thisOtherClass
                    case {'main','modify','analyse','generate'}
                        continue
                    case thisclass
                        functions = fieldnames(obj.handles.menu.dynamic.(thisOtherClass));
                        for iFunction = 1:numel(functions)
                            thisFunction = functions{iFunction};
                            obj.handles.menu.dynamic.(thisOtherClass).(thisFunction).Enable = 'on';
                        end
                    otherwise
                        functions = fieldnames(obj.handles.menu.dynamic.(thisOtherClass));
                        for iFunction = 1:numel(functions)
                            thisFunction = functions{iFunction};
                            obj.handles.menu.dynamic.(thisOtherClass).(thisFunction).Enable = 'off';
                        end
                end
            end

        end
        
        
        function selectlayer(obj,index)
            if nargin==1
                index = obj.handles.panelright.Value(1);
            end
            
            if ischar(index)
                switch index
                    case 'last'
                        index = numel(obj.Actors);
                    case 'first'
                        index = 1;
                    otherwise
                        keyboard
                end
            end
            
            %update the right box
            obj.handles.panelright.Value = index;
            
            if isempty(obj.Actors)
                return
            end
            %update the left box
            obj.Actors(index).updateCC(obj);
        end
        
        function clearconfigcontrols(obj)
            try
                 delete(obj.handles.configcontrols);
            catch
                disp('seems like handle was already deleted')
            end
            obj.handles.configcontrols = [];
            obj.configcontrolpos = 0;
            
        end
        
        function newconfigcontrol(obj,actor,type,value,tag,other)
            xpadding = 0.05;
            ypadding = 0.05;
            
            checkboxwidth = 0.3;
            checkboxheight = 0.1;
            colorwidth = 0.1;
            colorheight = 0.1;
            editheight = 0.1;
            textwidth = 0.2;
            editwidth = 0.1;
            popupwidth = 0.5;
            popupheight = 0.1;
            
            
            n = numel(obj.handles.configcontrols)+1;
            top = obj.configcontrolpos;
            left = 0;
            
            if not(iscell(value))
                value = {value};
                tag = {tag};
            end
            
            switch type
                case 'button'
                    left = textwidth+xpadding/2;
                    for i = 1:numel(value)
                        obj.handles.configcontrols(end+1) = uicontrol('style','push',...
                            'Parent',obj.handles.panelleft,...
                            'units','normalized',...
                            'position', [left+xpadding,1-ypadding-colorheight-top,colorwidth,colorheight],...
                            'String',value{i},...
                            'callback',{@cc_callback},...
                            'Tag',tag{i});
                        
                        left = left+xpadding+colorwidth;
                    end
                    obj.configcontrolpos = top+ypadding+colorheight;
                    
                case 'color'
                    left = textwidth+xpadding/2;
                    for i = 1:numel(value)
                        obj.handles.configcontrols(end+1) = uicontrol('style','push',...
                            'Parent',obj.handles.panelleft,...
                            'units','normalized',...
                            'position', [left+xpadding,1-ypadding-colorheight-top,colorwidth,colorheight],...
                            'String','',...
                            'callback',{@cc_selectcolor},...
                            'Tag',tag{i},...
                            'backgroundcolor',value{i});
                        
                        left = left+xpadding+colorwidth;
                    end
                    obj.configcontrolpos = top+ypadding+colorheight;
                    
                case 'checkbox'
                    for i = 1:numel(value)
                        left = textwidth+xpadding/2;
                        obj.handles.configcontrols(end+1) = uicontrol('style','checkbox',...
                            'Parent',obj.handles.panelleft,...
                            'units','normalized',...
                            'position',[left+xpadding,1-ypadding-checkboxheight-top,checkboxwidth,checkboxheight],...
                            'String',tag{i},...
                            'Tag',tag{i},...
                            'Value',value{i});
                        left = left+xpadding/2+checkboxwidth;
                    end
                case 'edit'
                    for i = 1:numel(value)
                        %label
                        obj.handles.configcontrols(end+1) = uicontrol('style','text',...
                            'Parent',obj.handles.panelleft,...
                            'units','normalized',...
                            'position',[left+xpadding,1-ypadding-editheight-top,textwidth,editheight],...
                            'String',tag{i},...
                            'HorizontalAlignment','right');
                        
                        left = left+xpadding+textwidth;
                        
                        %editbox
                        obj.handles.configcontrols(end+1) = uicontrol('style','edit',...
                            'Parent',obj.handles.panelleft,...
                            'units','normalized',...
                            'position',[left+xpadding/2,1-ypadding-editheight-top,editwidth,editheight],...
                            'String',num2str(value{i}),...
                            'Tag',tag{i});
                        
                        left = left+xpadding/2+editwidth;
                        
                    end
                    obj.configcontrolpos = top+ypadding+editheight;
                case 'vector'
                    for i = 1:numel(value)
                        %label
                        obj.handles.configcontrols(end+1) = uicontrol('style','text',...
                            'Parent',obj.handles.panelleft,...
                            'units','normalized',...
                            'position',[left+xpadding,1-ypadding-editheight-top,textwidth,editheight],...
                            'String',tag{i},...
                            'HorizontalAlignment','right');
                        
                        left = left+xpadding+textwidth;
                        
                        %editbox
                        obj.handles.configcontrols(end+1) = uicontrol('style','edit',...
                            'Parent',obj.handles.panelleft,...
                            'units','normalized',...
                            'position',[left+xpadding/2,1-ypadding-editheight-top,editwidth,editheight],...
                            'String',num2str(value{i}),...
                            'Tag',tag{i});
                        
                        left = left+xpadding/2+editwidth;
                        
                    end
                    obj.configcontrolpos = top+ypadding+editheight;
                    
                case 'list'
                    for i = 1:numel(value)
                        %label
                        obj.handles.configcontrols(end+1) = uicontrol('style','text',...
                            'Parent',obj.handles.panelleft,...
                            'units','normalized',...
                            'position',[left+xpadding,1-ypadding-editheight-top,textwidth,editheight],...
                            'String',tag{i},...
                            'HorizontalAlignment','right');
                        
                        left = left+xpadding+textwidth;
                        
                        %popupmenu
                        obj.handles.configcontrols(end+1) = uicontrol('style','popupmenu',...
                            'Parent',obj.handles.panelleft,...
                            'units','normalized',...
                            'position',[left+xpadding/2,1-ypadding-popupheight-top,popupwidth,popupheight],...
                            'String',other,...
                            'Value',find(contains(other,value{i})),...
                            'Tag',tag{i});
                        
                        left = left+xpadding/2+popupwidth;
                        
                    end
                    obj.configcontrolpos = top+ypadding+editheight;
                    
                otherwise
                    keyboard
                    
            end
            
            
            function cc_callback(hObject,eventdata)
                 scene = ArenaScene.getscenedata(hObject);
                 currentActors = ArenaScene.getSelectedActors(scene);
                 
                 %trigger callback at the actor
                 currentActors(1).callback(hObject.String)
            end
                 
                 
 
            function cc_selectcolor(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                color = A_colorpicker(scene.colorTheme);%uisetcolor;
                if length(color)==3
                    hObject.BackgroundColor = color;
                    
                    %trigger update button (nested function):
                    %UpdateButtonHandle = findobj('Tag','UpdateButton');
                    UpdateButtonHandle=hObject.Parent.Parent.UserData.handles.btn_updateActor;
                    feval(get(UpdateButtonHandle,'Callback'),UpdateButtonHandle,[]);
                end
            end
            
        end
        
        function saveas(obj,filename)
            savefig(obj.handles.figure,filename)
        end
        
        function hardclose(obj)
            global arena
            try
                deleteIndex = find(arena.Scenes==obj.handles.figure.UserData);
                arena.Scenes(deleteIndex) = [];
                delete(gcf)
            catch
                delete(gcf)
                warning('Scene was an orphan..')
            end
        end
    end
    
    methods(Static)
        
        function thisScene = getscenedata(h)
            while not(isa(h.UserData,'ArenaScene'))
                h = h.Parent;
            end
            thisScene = h.UserData;
        end
        
        function newsettings = ignoreUnchangedSettings(newsettings,actor)
            oldsettings = actor.Visualisation.settings;
            props = fieldnames(oldsettings);
            
            for iprop = 1:numel(props)
                thisprop = props{iprop};
                
                if not(ischar(oldsettings.(thisprop)))
                    if oldsettings.(thisprop)==newsettings.(thisprop)
                        newsettings.(thisprop) = nan;
                    end
                else
                    if strcmp(oldsettings.(thisprop),newsettings.(thisprop))
                        newsettings.(thisprop) = nan;
                    end
                end
            end
            
            
        end
        
        function color = getNewColor(scene)
            color = scene.colorTheme{numel(scene.Actors)+1};
            
        end
        
        function [currentActor,ind] = getSelectedActors(scene)
            ind = scene.handles.panelright.Value;
            if isempty(scene.Actors)
                currentActor = [];
                ind = [];
                disp('no actor in the scene')
                return
            end
            currentActor = scene.Actors(ind);
        end
        
        function classes = getClasses(actorlist)
            classes = {};
            for i = 1:numel(actorlist)
                classes{i} = class(actorlist(i).Data);
            end
        end
        
        function vd = countMesh(hObject)
            scene = ArenaScene.getscenedata(hObject);
            currentActors = ArenaScene.getSelectedActors(scene);
            currentClasses = ArenaScene.getClasses(currentActors);
            
            corner_1 = [inf inf inf];
            corner_2 = [-inf -inf -inf];
            voxelsize = inf;
            if all(or(contains(currentClasses,'Mesh'),contains(currentClasses,'Slice')))
                %find world limits
                for i = 1:numel(currentActors)
                    R = currentActors(i).Data.Source.R;
                    corner_1 = min([corner_1;R.XWorldLimits(1),R.YWorldLimits(1),R.ZWorldLimits(1)]);
                    corner_2 = max([corner_2;R.XWorldLimits(2),R.YWorldLimits(2),R.ZWorldLimits(2)]);
                    voxelsize = min([voxelsize,R.PixelExtentInWorldX,R.PixelExtentInWorldY,R.PixelExtentInWorldZ]);
                end
                imsize = round((corner_2-corner_1)/voxelsize);
                targetR = imref3d(imsize([2 1 3]),voxelsize,voxelsize,voxelsize);
                targetR.XWorldLimits = targetR.XWorldLimits - voxelsize/2 + corner_1(1);
                targetR.YWorldLimits = targetR.YWorldLimits - voxelsize/2 + corner_1(2);
                targetR.ZWorldLimits = targetR.ZWorldLimits - voxelsize/2 + corner_1(3);
                
                
                %initialize output
                outputVoxels = double(currentActors(1).Data.Source.warpto(targetR).Voxels > currentActors(1).Data.Settings.T);
                
                %loop over remaining
                for i = 2:numel(currentActors)
                    outputVoxels = outputVoxels+double(currentActors(i).Data.Source.warpto(targetR).Voxels > currentActors(i).Data.Settings.T);
                end
                
                vd = VoxelData(outputVoxels,targetR);
            else
                disp('only supports meshes and slices as input')
                vd = VoxelData;
            end
        end
        
        
    end
end


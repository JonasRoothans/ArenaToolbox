classdef ArenaScene < handle
    %ARENASCENE Generates UIobjects, and stores Actors.
    %   This class is the central class of the ArenaToolbox.
    %   You can open a scene with: 
    %   -   myScene = newScene();
    %   -   or startArena;
    %
    %   See also ARENAACTOR
    
    properties
        Title
        Actors = ArenaActor.empty;
        VTAstorage = VTA.empty;
        Therapystorage = Therapy.empty;
        handles
        SceneLocation = '';
    end
    
    properties (Hidden=true)
        CallFromOutside
        configcontrolpos % stores the bounding box of the uicontrols
        colorTheme
        gitref
    end
    
    methods
        function obj = ArenaScene()
            %ARENAWINDOW Construct an instance of this class
            %   Detailed explanation goes here
            
            global predictionmanager 
                if not(isa(predictionmanager,'PredictionManager'))
                    [predictionmanager] = PredictionManager();
                end
                
            global connectomes
                if not(isa(connectomes,'ConnectomeManager'))
                    connectomes = ConnectomeManager;
                end
                
                
        end
        
        %this function contains also contains all callbacks as subfunctions
        function obj = create(obj,OPTIONALname)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
           
            debugmode = 0;
            
            if debugmode
                userinput = {'debug mode'};
            else
                if nargin==1
                  
                    Classdirectory=fileparts(mfilename('fullpath'));
                    idcs   = strfind(Classdirectory,filesep);
                    parentdirectory = Classdirectory(1:idcs(end)-1);
                    fid = fopen(fullfile([parentdirectory,filesep,'Elements',filesep,'Misc'],'sceneNameSuggestion.txt'));
                    try
                           data = textscan(fid,'%s');
                             
                    catch
                        error('cannot find file looks like you have changed the organisation of subfolders in Arena files')
                    end
                  
                   rand(1);  
                    randomName = data{1}{ceil(rand(1)*length(data{1}))};
                    
                    userinput = newid({'new scene name: '},'Arena',1,{randomName});
                elseif nargin==2
                    userinput = {OPTIONALname};
                end
            end
            if isempty(userinput);return;end
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
                'box','off',...
                'tag','Main Axes');
            axis off
            daspect([1 1 1])
            
            %---- Orientation marker
            obj.handles.axesOrientation = axes('units','normalized',...
                'position',[0 0.9,0.08,0.08],...
                'box','off',...
                'tag','Marker',...
                'CameraViewAngleMode','Manual',...
                'ButtonDownFcn','disp(''axis callback'')');
            axis off
            
            daspect([1 1 1]);
            obj.handles.light1_patientorientationmarker = light('Position',[-1 0 0.5],'Style','infinite');
            obj.handles.light2_patientorientationmarker = light('Position',[1 0 0.5],'Style','infinite');
            obj.handles.light3_patientorientationmarker = light('Position',[0 1 0],'Style','infinite');
            Marker = ObjFile;
            Marker = Marker.loadfile('PatientOrientationMarker.obj');
            Marker.Vertices(:,2) = Marker.Vertices(:,2)*-1;
            axes(obj.handles.axesOrientation)
            obj.handles.orientationMarker = patch('Faces',Marker.Faces,'Vertices',Marker.Vertices);
            obj.handles.orientationMarker.HitTest = 'off';
            obj.handles.orientationMarker.FaceColor = [0.5 0.5 0.5];
            obj.handles.orientationMarker.FaceAlpha = 1;
            obj.handles.orientationMarker.EdgeAlpha = 0;
            obj.handles.orientationMarker.FaceLighting = 'gouraud';           
            material(obj.handles.orientationMarker,[0.8 0.5 0]);
            obj.handles.axesOrientation.HitTest = 'off';
            %link to orientation marker
            linkprop([obj.handles.axes,obj.handles.axesOrientation],{'View'});
             axes(obj.handles.axes)
            
            %----
            
            
            
            
            
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
            
            %refresh menu
            obj.handles.templates =  menu_refreshTemplatelist(obj,[],'startup');
            

 
            
            
            
            
            %menubar
            obj.handles.menu.file.main = uimenu(obj.handles.figure,'Text','File');
            
            obj.handles.menu.file.newscene.main = uimenu(obj.handles.menu.file.main,'Text','New empty scene','callback',{@menu_newscene});
            obj.handles.menu.file.savesceneas.main = uimenu(obj.handles.menu.file.main,'Text','Save scene as','callback',{@menu_savesceneas});
            obj.handles.menu.file.savescene.main = uimenu(obj.handles.menu.file.main,'Text','Save scene','callback',{@menu_savescene});
            obj.handles.menu.file.import.main = uimenu(obj.handles.menu.file.main,'Text','Import actor [cmd+i]','callback',{@menu_importAnything},'Enable','on','Separator','on');
            obj.handles.menu.file.import.fromworkspace = uimenu(obj.handles.menu.file.main,'Text','Import actor from workspace [cmd+shift+i]','callback',{@menu_importfromworkspace});            
            obj.handles.menu.file.new.main = uimenu(obj.handles.menu.file.main,'Text','New actor');
            obj.handles.menu.file.new.electrode = uimenu(obj.handles.menu.file.new.main,'Text','Electrode','callback',{@menu_placeElectrode});
            obj.handles.menu.file.new.vta= uimenu(obj.handles.menu.file.new.main,'Text','Åström VTA','callback',{@menu_generateVTA});
            obj.handles.menu.file.export.main = uimenu(obj.handles.menu.file.main,'Text','Export');
            obj.handles.menu.file.export.wiggle = uimenu(obj.handles.menu.file.export.main,'Text','wiggle (*.mp4)','callback',{@menu_wiggle});
            obj.handles.menu.file.export.blender = uimenu(obj.handles.menu.file.export.main,'Text','Blender (*.obj)','callback',{@menu_exporttoblender});
            obj.handles.menu.file.export.handlestoworkspace = uimenu(obj.handles.menu.file.export.main,'Text','handles to workspace','callback',{@menu_exporthandlestoworkspace});
            obj.handles.menu.file.export.saveSelection = uimenu(obj.handles.menu.file.export.main,'Text','selection to folder','callback',{@menu_saveSelectionToFolder});
            obj.handles.menu.file.settings = uimenu(obj.handles.menu.file.main,'Text','Reset to factory settings','callback',{@menu_resetSettings});
            
            
            obj.handles.menu.stusessions.main = uimenu(obj.handles.figure,'Text','Suretune sessions','Visible','off','Separator','on');
            obj.handles.menu.stusessions.openwindows = {};
            
            obj.handles.menu.vtas.main = uimenu(obj.handles.figure,'Text','Prediction','Visible','on','Separator','on','callback',{@menu_updateVTAlist});
            obj.handles.menu.vtas.assignVTA = uimenu(obj.handles.menu.vtas.main,'Text','assign host for predictions','callback',{@menu_constructVTA});
            %obj.handles.menu.vtas.placeElectrode = uimenu(obj.handles.menu.vtas.main,'Text','+place electrode','callback',{@menu_placeElectrode});
            obj.handles.menu.vtas.constructtherapy = uimenu(obj.handles.menu.vtas.main,'Text','construct (bilateral) therapy','callback',{@menu_constructTherapy});
            obj.handles.menu.vtas.batchprediction.main = uimenu(obj.handles.menu.vtas.main,'Text','run batch prediction');
            obj.handles.menu.vtas.batchprediction.electrodes = uimenu(obj.handles.menu.vtas.batchprediction.main,'Text','run batch on electrodes','callback',{@menu_runbatch_electrodes});
            obj.handles.menu.vtas.batchprediction.bilateraltherapy = uimenu(obj.handles.menu.vtas.batchprediction.main,'Text','run batch on bilateral therapy','callback',{@menu_runbatch_bilateraltherapy});
            scene.handles.menu.vtas.batchprediction.main.Enable='off';
            obj.handles.menu.vtas.list = gobjects;
            obj.handles.menu.vtas.therapylist = gobjects;
            
            obj.handles.menu.view.main = uimenu(obj.handles.figure,'Text','View','callback',{@menu_surgicalview});
            obj.handles.menu.view.camera.main = uimenu(obj.handles.menu.view.main,'Text','Camera');
            obj.handles.menu.view.camera.focus.main = uimenu(obj.handles.menu.view.camera.main,'Text','Focus on');
            
            obj.handles.menu.view.camera.focus.actor = uimenu( obj.handles.menu.view.camera.focus.main,'Text','Selection [.]','callback',{@menu_camTargetActor});
            obj.handles.menu.view.camera.focus.origin = uimenu( obj.handles.menu.view.camera.focus.main,'Text','Origin [o]','callback',{@menu_camTargetOrigin});
            
            
            obj.handles.menu.view.camera.orthogonal.main = uimenu(obj.handles.menu.view.camera.main,'Text','Orthogonal');
            obj.handles.menu.view.camera.orthogonal.axial = uimenu(obj.handles.menu.view.camera.orthogonal.main,'Text','Axial [shift+1]','callback',{@menu_orthogonal});
            obj.handles.menu.view.camera.orthogonal.sagittal = uimenu(obj.handles.menu.view.camera.orthogonal.main,'Text','Sagittal [shift+2]','callback',{@menu_orthogonal});
            obj.handles.menu.view.camera.orthogonal.coronal = uimenu(obj.handles.menu.view.camera.orthogonal.main,'Text','Coronal [shift+3]','callback',{@menu_orthogonal});
            
            obj.handles.menu.view.camera.surgical.main = uimenu(obj.handles.menu.view.camera.main,'Text','Surgical');
            obj.handles.menu.view.camera.surgical.electrodes = []; %will be filled by view main call back.
            
            obj.handles.menu.view.camera.smart.main = uimenu(obj.handles.menu.view.camera.main,'Text','Smart Perspective');
            obj.handles.menu.view.camera.smart.vertical = uimenu(obj.handles.menu.view.camera.smart.main,'Text','based on selection','callback',{@menu_smartcamperspective});
            
            
            obj.handles.menu.view.camera.multi.cameralist = {};
            obj.handles.menu.view.camera.multi.currentcam = 1;
            obj.handles.menu.view.camera.multi.main = uimenu(obj.handles.menu.view.camera.main,'Text','Multi');
            obj.handles.menu.view.camera.multi.new = uimenu(obj.handles.menu.view.camera.multi.main,'Text','New Camera','callback',{@menu_camera_new});
            obj.handles.menu.view.camera.multi.cam{1} = uimenu(obj.handles.menu.view.camera.multi.main,'Text','1','Checked','on','Separator','on','callback',{@menu_camera_switch});
            
            
            
            obj.handles.menu.view.lights.main = uimenu(obj.handles.menu.view.main,'Text','Lights');
            obj.handles.menu.view.lights.sun = uimenu(obj.handles.menu.view.lights.main,'Text','Sun','callback',{@menu_showLight_sun},'Checked','on');
            obj.handles.menu.view.lights.ground = uimenu(obj.handles.menu.view.lights.main,'Text','Bottom light','callback',{@menu_showLight_ground},'Checked','off');
            obj.handles.menu.view.lights.cameraposition = uimenu(obj.handles.menu.view.lights.main,'Text','place light at camera position','callback',{@menu_placeLight});
            
            
            obj.handles.menu.view.flat.main = uimenu(obj.handles.menu.view.main,'Text','2D','Separator','on','callback',{@menu_intersectPlane});
            obj.handles.menu.view.bgcolor.main = uimenu(obj.handles.menu.view.main,'Text','background color');
            obj.handles.menu.view.bgcolor.white = uimenu(obj.handles.menu.view.bgcolor.main ,'Text','White','callback',{@menu_setbackgroundcolor});
            obj.handles.menu.view.bgcolor.light = uimenu(obj.handles.menu.view.bgcolor.main ,'Text','Light','callback',{@menu_setbackgroundcolor});
            obj.handles.menu.view.bgcolor.dark = uimenu(obj.handles.menu.view.bgcolor.main ,'Text','Dark','callback',{@menu_setbackgroundcolor});
            obj.handles.menu.view.bgcolor.black = uimenu(obj.handles.menu.view.bgcolor.main ,'Text','Black','callback',{@menu_setbackgroundcolor});
            obj.handles.menu.view.bgcolor.custom = uimenu(obj.handles.menu.view.bgcolor.main ,'Text','Custom','callback',{@menu_setbackgroundcolor});
            
            obj.handles.menu.view.dynamictransparanncy.main = uimenu(obj.handles.menu.view.main,'Text','Dynamic slice transparancy','Checked',0,'callback',{@menu_setdynamictransparancy});
            obj.handles.menu.view.OrientationMarker.main = uimenu(obj.handles.menu.view.main,'Text','Orientation Marker','Checked',1,'callback',{@menu_showOrientationMarker});
            
            
            obj.handles.menu.atlas.main = uimenu(obj.handles.figure,'Text','Atlas');
            obj.handles.menu.atlas.lead.main = uimenu(obj.handles.menu.atlas.main,'Text','from leadDBS (MNI_2022)','callback',{@menu_atlasleaddbs});
            obj.handles.menu.atlas.suretune.main = uimenu(obj.handles.menu.atlas.main ,'Text','from SureTune (MNI_2022)');
            obj.handles.menu.atlas.suretune.stn = uimenu(obj.handles.menu.atlas.suretune.main ,'Text','STN','callback',{@menu_legacyatlas});
            obj.handles.menu.atlas.suretune.gpi = uimenu(obj.handles.menu.atlas.suretune.main ,'Text','GPi','callback',{@menu_legacyatlas});
            obj.handles.menu.atlas.suretune.other = uimenu(obj.handles.menu.atlas.suretune.main ,'Text','Other','callback',{@menu_legacyatlas});
            obj.handles.menu.atlas.MRI.main = uimenu(obj.handles.menu.atlas.main,'Text','MRI template');
            obj.handles.menu.atlas.MRI.update = uimenu(obj.handles.menu.atlas.MRI.main,'Text','[Refresh list]','callback',{@menu_refreshTemplatelist,'user'});
            for iMRItemplate = 1:numel(obj.handles.templates)
                obj.handles.menu.atlas.MRI.template(iMRItemplate) = uimenu(obj.handles.menu.atlas.MRI.main,'Text',obj.handles.templates(iMRItemplate).name,'callback',{@menu_addMRItemplate,obj.handles.templates(iMRItemplate)});
            end
            
           
            
            
            
            
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
            
            
            %obj.handles.menu.edit.intersectplane = uimenu(obj.handles.menu.edit.main,'Text','project to plane','callback',{@menu_intersectPlane});
            %obj.handles.menu.edit.pointclouddistribution = uimenu(obj.handles.menu.edit.main,'Text','pointcloud distribution','callback',{@menu_pcDistribution});
            %obj.handles.menu.edit.pointcloudanalysis = uimenu(obj.handles.menu.edit.main,'Text','PointCloud in mesh','callback',{@menu_pointcloudinmesh});
            obj.handles.menu.edit.duplicate = uimenu(obj.handles.menu.edit.main,'Text','Duplicate layer','callback',{@menu_duplicate});
            %obj.handles.menu.edit.obj2mesh = uimenu(obj.handles.menu.edit.main,'Text','Turn Object to Mesh','callback',{@menu_obj2mesh});
            
            
            
            
            obj.handles.menu.transform.main = uimenu(obj.handles.menu.edit.main,'Text','Transform selection','callback',{@menu_electrodespace}); %relocated
            %obj.handles.menu.transform.selectedlayer.main = uimenu(obj.handles.menu.transform.main,'Text','Selected Layer');
            obj.handles.menu.transform.selectedlayer.old.main = uimenu(obj.handles.menu.transform.main,'Text','historical');
            obj.handles.menu.transform.selectedlayer.simple.main = uimenu(obj.handles.menu.transform.main,'Text','simple');
            obj.handles.menu.transform.selectedlayer.transformInElectrodeSpace.main = uimenu(obj.handles.menu.transform.main,'Text','move / rotate in electrode space');
            obj.handles.menu.transform.selectedlayer.transformInElectrodeSpace.electrodes=[]; %will be added automatically with the menu_electrodespace function.
            
            obj.handles.menu.transform.selectedlayer.lps2ras = uimenu(obj.handles.menu.transform.selectedlayer.old.main,'Text','LPS <> RAS','callback',{@menu_lps2ras});
            obj.handles.menu.transform.selectedlayer.mirror = uimenu(obj.handles.menu.transform.selectedlayer.simple.main,'Text','mirror left/right','callback',{@menu_mirror});
            obj.handles.menu.transform.selectedlayer.yeb2mni = uimenu(obj.handles.menu.transform.selectedlayer.old.main,'Text','Legacy 2019 --> arena2021','callback',{@menu_Fake2MNI});
            obj.handles.menu.transform.selectedlayer.arena2leadmni.main = uimenu(obj.handles.menu.transform.main,'Text','arena2021 to arena2022');
            
            obj.handles.menu.transform.selectedlayer.arena2leadmni.leftstn = uimenu(obj.handles.menu.transform.selectedlayer.arena2leadmni.main, 'Text','leftSTN','callback',{@menu_MNI2leaddbsMNI});
            obj.handles.menu.transform.selectedlayer.arena2leadmni.rightstn = uimenu(obj.handles.menu.transform.selectedlayer.arena2leadmni.main, 'Text','rightSTN','callback',{@menu_MNI2leaddbsMNI});
            obj.handles.menu.transform.selectedlayer.arena2leadmni.leftgpi = uimenu(obj.handles.menu.transform.selectedlayer.arena2leadmni.main, 'Text','leftGPI','callback',{@menu_MNI2leaddbsMNI});
            obj.handles.menu.transform.selectedlayer.arena2leadmni.rightgpi = uimenu(obj.handles.menu.transform.selectedlayer.arena2leadmni.main, 'Text','rightGPI','callback',{@menu_MNI2leaddbsMNI});
            obj.handles.menu.transform.selectedlayer.move =  uimenu(obj.handles.menu.transform.selectedlayer.simple.main,'Text','Move','callback',{@menu_move});
            obj.handles.menu.transform.selectedlayer.transformationmatrix =  uimenu(obj.handles.menu.transform.selectedlayer.simple.main,'Text','Transformation matrix from workspace','callback',{@menu_moveTransformationMatrix});
            
            obj.handles.menu.addons.main = uimenu(obj.handles.figure,'Text','Add-ons');
            menu_refreshAddOnsList(obj,[],'startup');
            
            
            %-- dynamic
            obj.handles.menu.dynamic.main  = uimenu(obj.handles.figure,'Text','...');
            obj.handles.menu.dynamic.modify.main = uimenu(obj.handles.menu.dynamic.main ,'Text','Modify');
            obj.handles.menu.dynamic.analyse.main = uimenu(obj.handles.menu.dynamic.main ,'Text','Analyse');
            obj.handles.menu.dynamic.generate.main = uimenu(obj.handles.menu.dynamic.main ,'Text','Generate');
            
            
            obj.handles.menu.dynamic.ObjFile.obj2mesh = uimenu(obj.handles.menu.dynamic.generate.main,'Text','ObjFile: convert to Mesh','callback',{@menu_obj2mesh},'Enable','off');
            
            
            obj.handles.menu.dynamic.PointCloud.distribution = uimenu(obj.handles.menu.dynamic.analyse.main,'Text','PointCloud: show distribution','callback',{@menu_pcDistribution},'Enable','off');
            obj.handles.menu.dynamic.PointCloud.inMesh = uimenu(obj.handles.menu.dynamic.analyse.main,'Text','PointCloud: is a point inside a mesh?','callback',{@menu_pointcloudinmesh},'Enable','off');
            obj.handles.menu.dynamic.PointCloud.mergePointClouds = uimenu(obj.handles.menu.dynamic.generate.main,'Text','PointCloud: merge pointclouds','callback',{@menu_mergePointCloud},'Enable','off');
            obj.handles.menu.dynamic.PointCloud.twoSampleTTest = uimenu(obj.handles.menu.dynamic.analyse.main,'Text','PointCloud: two sample t-test','callback',{@menu_pc2samplettest},'Enable','off');
            obj.handles.menu.dynamic.PointCloud.burnIn = uimenu(obj.handles.menu.dynamic.generate.main,'Text','PointCloud: burn in to template','callback',{@menu_burnPointCloudIntoVoxelData},'Enable','off');
            
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
            obj.handles.menu.dynamic.Mesh.makeBinarySlice = uimenu(obj.handles.menu.dynamic.generate.main,'Text','Mesh: convert to binary slice','callback',{@menu_mesh2binaryslice},'Enable','off');
            obj.handles.menu.dynamic.Mesh.SpatialCorrelation = uimenu(obj.handles.menu.dynamic.analyse.main,'Text','VoxelData: spatial correlation','callback',{@menu_spatialcorrelation},'Enable','off');
            obj.handles.menu.dynamic.Mesh.seperate = uimenu(obj.handles.menu.dynamic.generate.main,'Text','Mesh: separate clusters','callback',{@menu_seperateClusters},'Enable','off');
            obj.handles.menu.dynamic.Mesh.addToVTApool = uimenu(obj.handles.menu.dynamic.generate.main,'Text','Mesh: add to VTApool','callback',{@menu_addToVTApool},'Enable','off');
            obj.handles.menu.dynamic.Mesh.smooth = uimenu(obj.handles.menu.dynamic.modify.main,'Text','Mesh: source data','callback',{@menu_smoothVoxelData},'Enable','off');
            obj.handles.menu.dynamic.Mesh.takeBite = uimenu(obj.handles.menu.dynamic.analyse.main,'Text','Mesh: take a sample from slice or mesh','callback',{@menu_takeSample},'Enable','off');
            obj.handles.menu.dynamic.Mesh.detectElectrode = uimenu(obj.handles.menu.dynamic.analyse.main,'Text','Mesh: convert to electrode','callback',{@menu_detectElectrode},'Enable','off');
            obj.handles.menu.dynamic.Slicei.SpatialCorrelation = obj.handles.menu.dynamic.Mesh.SpatialCorrelation;
            
            obj.handles.menu.dynamic.Slicei.multiply = uimenu(obj.handles.menu.dynamic.modify.main,'Text','Slice: multiply images','callback',{@menu_multiplyslices},'Enable','off');
            obj.handles.menu.dynamic.Slicei.smooth = uimenu(obj.handles.menu.dynamic.modify.main,'Text','Slice: smooth','callback',{@menu_smoothslice},'Enable','off');
            obj.handles.menu.dynamic.Slicei.mask = uimenu(obj.handles.menu.dynamic.modify.main,'Text','Slice: apply mask','callback',{@menu_applyMask},'Enable','off');
            obj.handles.menu.dynamic.Slicei.segmentElectrode = uimenu(obj.handles.menu.dynamic.generate.main,'Text','Slice: extract Lead From CT','callback',{@menu_extractLeadFromCT},'Enable','off');
            
            obj.handles.menu.dynamic.Fibers.interferenceWithMap = uimenu(obj.handles.menu.dynamic.analyse.main,'Text','Fibers: interference with map','callback',{@menu_fiberMapInterference},'Enable','off');
            obj.handles.menu.dynamic.Fibers.exportSummary = uimenu(obj.handles.menu.dynamic.analyse.main,'Text','Fibers: export fiber summary','callback',{@menu_fiberSummary},'Enable','off');
            obj.handles.menu.dynamic.Fibers.exportSummary = uimenu(obj.handles.menu.dynamic.modify.main,'Text','Fibers: generate ROI from endpoints','callback',{@menu_fibersToROI},'Enable','off');
                      
                      
            %obj.handles.cameratoolbar = cameratoolbar(obj.handles.figure,'Show');
            obj.handles.cameratoolbar = A_cameratoolbar(obj.handles.figure);
            obj.handles.lightSun = light('Position',[0 0 1],'Style','infinite');
            obj.handles.lightGround = light('Position',[0 0 -1],'Style','infinite');
            obj.handles.lightGround.Visible = 'on';
            obj.handles.light = light('Position',[1 1 1],'Style','local');
            
            
            obj = createcoordinatesystem(obj);
            obj = setColorTheme(obj,'default');
            
            lighting gouraud
            camproj('perspective')
            view(30,30)
            
            %Open-up functions to call from outside!
            obj.CallFromOutside.import_vtk  = @import_vtk;
            obj.CallFromOutside.fiberMapInterference = @fiberMapInterference;
            
            %... add more
            
            
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
            function menu_addMRItemplate(hObject,eventdata,template)
                scene = ArenaScene.getscenedata(hObject);
                templateVD = VoxelData;
                templateVD.loadnii(template.path,true); %noreslice = true
                template_actor = templateVD.getslice.see(scene);
                template_actor.changeName(template.name);
                
                %set background to black
                scene.handles.figure.Color
            end
            
            function menu_resetSettings(hObject,eventdata,custom)
                global arena
                arena.setup();
                msgbox('Reset succesful, please restart MATLAB','Warning','warn')
                
            end
            
            function menu_refreshAddOnsList(hObject,eventdata,custom)
                if strcmp(custom,'startup')
                    scene = hObject;
                else
                scene = ArenaScene.getscenedata(hObject);
                end
                
                addondir = fullfile(fileparts(fileparts(mfilename('fullpath'))),'add-ons');
                 if not(isfolder(addondir))
                    mkdir(addondir)
                 end
                 %--- hard refresh when triggered by user
                 if strcmp(custom,'user') %user triggers a hard refresh
                     items = fieldnames(scene.handles.menu.addons);
                     for iItem = 1:numel(items)
                         switch items{iItem}
                             case 'main'
                                 %do nothing
                             otherwise
                                 delete(scene.handles.menu.addons.(items{iItem}))
                         end
                     end
                 end
                 
                 
                 %--- loop over subfolders
                 subfolders = SDK_subfolders(addondir);
                 for iSubfolder = 1:numel(subfolders)
                     installationFile = dir(fullfile(addondir,subfolders{iSubfolder},'install_*.m'));
                     if isempty(installationFile)
                         disp(['Add-ons: ',subfolders{iSubfolder},' cannot be installed.'])
                         continue
                     end
                     callback = str2func(installationFile(1).name(1:end-2)); %without .m
                     scene.handles.menu.addons.(subfolders{iSubfolder}).main =  uimenu(scene.handles.menu.addons.main,'Text',['add: ',subfolders{iSubfolder}],'callback',{callback,scene});
                     disp(['Add-ons: ',subfolders{iSubfolder},' is available.'])
                     addpath(fullfile(addondir,subfolders{iSubfolder}))
                 end
                 
            end
            
            
           
            
            
            function templatelist =  menu_refreshTemplatelist(hObject,eventdata,custom)
                
                 templatedir = fullfile(fileparts(fileparts(mfilename('fullpath'))),'UserData','Templates');
                if not(isfolder(templatedir))
                    scene = ArenaScene.getscenedata(hObject);
                    
                end
                
                
                
                
                obj.handles.templates = [];
                templates = dir(fullfile(templatedir,'*.nii'));
                templatelist = [];
                for iTemplate = 1:numel(templates)
                   templatelist(iTemplate).path = fullfile(templatedir,templates(iTemplate).name);
                   templatelist(iTemplate).name = templates(iTemplate).name;
                end
                
                if strcmp(custom,'user')
                    scene = ArenaScene.getscenedata(hObject);
                    if isempty(iTemplate)
                        msgbox('No .nii files are detected in the folder: ArenaToolbox/UserData/Templates')
                        return
                    end
                    
                    %refresh the handles
                   for iDelete = 1:numel(obj.handles.menu.atlas.MRI.template)
                        delete(obj.handles.menu.atlas.MRI.template(iDelete))
                   end
                   for iAdd = 1:numel(templatelist)
                        scene.handles.menu.atlas.MRI.template(iAdd) = uimenu(scene.handles.menu.atlas.MRI.main,'Text',templatelist(iAdd).name,'callback',{@menu_addMRItemplate,templatelist(iAdd)});
                    end
                    
                end

            end
            
            function menu_showLight_sun(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                switch hObject.Checked
                    case 'on'
                        scene.handles.lightSun.Visible = 'off';
                        hObject.Checked = 'off';
                    case 'off'
                        scene.handles.lightSun.Visible = 'on';
                        hObject.Checked = 'on';
                end
            end
            
            
             function menu_showLight_ground(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                switch hObject.Checked
                    case 'on'
                        scene.handles.lightGround.Visible = 'off';
                        hObject.Checked = 'off';
                    case 'off'
                        scene.handles.lightGround.Visible = 'on';
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
                disp('Saving a scene can take up to several minutes!')
                save(fullfile(pathname,filename),'Scene','-v7.3');
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
                dirname = uigetdir('');
                for iActor = 1:numel(actorList)
                    thisActor = actorList(iActor);
                    thisActor.export3d(dirname);
                end
                
                disp('File saved to current directory')
            end
            
            function menu_exporthandlestoworkspace(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                assignin('base','scene',scene);
                assignin('base','actors',scene.Actors);
                for i = 1:numel(scene.Actors)
                    fprintf('%d. (%s) %s\n',i,class(scene.Actors(i).Data),scene.Actors(i).Tag)
                end
                disp('handles saved to workspace: scene, actors')
            end
            
            function menu_surgicalview_electrode(hObject,evendata,e)
                scene = ArenaScene.getscenedata(hObject);
              
                
                current_campos = campos;
                current_target = camtarget;
                %current_camup = camup;
                
                distance = norm(current_target-current_campos);
                
                
              
                
                new_target = e.Data.C0;
                new_campos = e.Data.C0 + e.Data.Direction * distance;
                %new_camup = cross(e.Data.Direction,Vector3D([1 0 0]));
                
                axes(scene.handles.axesOrientation)
                
                %camup([1 0 0])
                campos(new_campos.getArray())
                camtarget(new_target.getArray())
                
                axes(scene.handles.axes)
                %camup([1 0 0])
                campos(new_campos.getArray())
                camtarget(new_target.getArray())
                
            end
            
            
            function menu_surgicalview(hObject,eventdata)
                
                 %get electrodes
                scene = ArenaScene.getscenedata(hObject);
                 arrayfun(@(x) delete(x), obj.handles.menu.view.camera.surgical.electrodes);
                currentActors = ArenaScene.getSelectedActors(scene);
                [actorlist,namelist,indexlist] =  ArenaScene.getActorsOfClass(scene,'Electrode');
                
                for iActor = 1:numel(actorlist)
                %list all the electrodes here. with a callback to
                %move/rotate with respect to this electrode.
                    obj.handles.menu.view.camera.surgical.electrodes(iActor) = uimenu(obj.handles.menu.view.camera.surgical.main,'Text',namelist{iActor},'callback',{@menu_surgicalview_electrode,actorlist(iActor)});
                
                
                end
                
            end
            
            function menu_electrodespace(hObject,eventdata)
                %get electrodes
                scene = ArenaScene.getscenedata(hObject);
                 arrayfun(@(x) delete(x), scene.handles.menu.transform.selectedlayer.transformInElectrodeSpace.electrodes);
                currentActors = ArenaScene.getSelectedActors(scene);
                [actorlist,namelist,indexlist] =  ArenaScene.getActorsOfClass(scene,'Electrode');
                
                for iActor = 1:numel(actorlist)
                %list all the electrodes here. with a callback to
                %move/rotate with respect to this electrode.
                    obj.handles.menu.transform.selectedlayer.transformInElectrodeSpace.electrodes(iActor) = uimenu(obj.handles.menu.transform.selectedlayer.transformInElectrodeSpace.main,'Text',namelist{iActor},'callback',{@menu_transformInLeadSpace,actorlist(iActor)});
                
                
                end
            end
            
            function menu_transformInLeadSpace(hObject,eventdata,e)
                scene = ArenaScene.getscenedata(hObject);
                currentActors = ArenaScene.getSelectedActors(scene);
                T = e.Data.getTransformToRoot;
                Ti = e.Data.getTransformFromRoot;
                
                input = newid({'Rotation clockwise in deg:','Followed by a translation: '},'Arena',1,{'0','[0 0 0]'});
                    translation = eval(input{2});
                    
                    alpha = deg2rad(str2double(input{1}));
                    Tuser = [cos(alpha), -1*sin(alpha), 0 ,0;...
                        sin(alpha),cos(alpha), 0, 0;...
                        0 0 1 0;...
                       translation(1),translation(2),translation(3),1];
                
                for iActor = 1:numel(currentActors)
                    thisActor = currentActors(iActor);
                    
                    
                    Tfinal = round(T*Tuser*Ti,5);
                    
                    thisActor.transform(scene,'T',Tfinal)
                    
                    
                    
                end
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
                        thisActor.transform(scene,'mirror')
                    end
                    thisActor.changeName(['[mirror]  ',thisActor.Tag])
                end
                
                
            end
            
            function menu_duplicate(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                actorList = ArenaScene.getSelectedActors(scene);
                for iActor = 1:numel(actorList)
                    thisActor = actorList(iActor);
                    copyActor = thisActor.duplicate(scene);
                    copyActor.changeName(['copy of  ',copyActor.Tag])
                    
                end
            end
            
            function menu_obj2mesh(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                actorList = ArenaScene.getSelectedActors(scene);
                for iActor = 1:numel(actorList)
                    thisActor = actorList(iActor);
                    thisActor.obj2mesh(scene);
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
        
            function menu_moveTransformationMatrix(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                currentActors = ArenaScene.getSelectedActors(scene);
                
                allVariables = evalin('base','whos'); 
                
                matchesdouble= strcmp({allVariables.class}, 'double');
                matchesaffine= strcmp({allVariables.class}, 'affine3d');
                my_variables = {allVariables(or(matchesdouble,matchesaffine)).name};
                
                indx = listdlg('ListString',my_variables);
                
                transformation_matrix = evalin('base',my_variables{indx});
                
                if isnumeric(transformation_matrix)
                    if not(numel(transformation_matrix)==16)
                        error('Transformation matrix has to be 4x4')
                    end
                else
                    transformation_matrix = transformation_matrix.T;
                end
                
                for i = 1:numel(currentActors)
                    thisActor = currentActors(i);
                    thisActor.transform(scene,'T',transformation_matrix);
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
            
            
            function menu_MNI2leaddbsMNI(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                currentActors = ArenaScene.getSelectedActors(scene);
                
                button = hObject.Text;
                T = load('T2022');
                
                
                    
                
                for i = 1:numel(currentActors)
                    thisActor = currentActors(i);
                    thisActor.transform(scene,'T',round(T.(['arena2mni_',button]),5));
                    currentName = thisActor.Tag;
                    label = '[mni2022]  ';
                    if contains(currentName,label)
                        newname = erase(currentName,label);
                    else
                        newname = [label,currentName];
                    end
                    thisActor.changeName(newname)
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
            
            
            function menu_showOrientationMarker(hObject,eventdata)
                thisScene = ArenaScene.getscenedata(hObject);
                switch hObject.Checked
                    case 'on'
                        hObject.Checked = 'off';
                        thisScene.handles.axesOrientation.Children(1).Visible  = 'off';
                    case 'off'
                        hObject.Checked = 'on';
                        thisScene.handles.axesOrientation.Children(1).Visible  = 'on';
                end
            end
            
            function menu_setdynamictransparancy(hObject,eventdata)
                switch hObject.Checked
                    case 'on'
                        hObject.Checked = 'off';
                    case 'off'
                        hObject.Checked = 'on';
                end
                
            end
            
            function menu_atlasleaddbs(hObject,eventdata)
                %get the rootdir to load the config file
                global arena;
                root = arena.getrootdir;
                loaded = load(fullfile(root,'config.mat'));
                
                leadDBSatlasdir = fullfile('templates','space','MNI_ICBM_2009b_NLIN_ASYM','atlases');
  
                subfolders = A_getsubfolders(fullfile(loaded.config.leadDBS,leadDBSatlasdir));
                options = {subfolders.name};
                options{end+1} = '[Cracked] Distal Atlas - 100% virus free - aXXo';
                [indx,tf] = listdlg('ListString',options,'ListSize',[400,320]);
                if indx ~= length(options)
                    newAtlasPath = fullfile(loaded.config.leadDBS,...
                    leadDBSatlasdir,...
                    subfolders(indx).name,'atlas_index.mat');
                else
                    newAtlasPath = fullfile(arena.getrootdir,'Elements/Misc/Distal_Medium','atlas_index.mat');
                end
                in = load(newAtlasPath);
                
                allnames = in.atlases.names;
                
                [indx,tf] = listdlg('ListString',allnames,'SelectionMode','multiple');
                thisScene = ArenaScene.getscenedata(hObject);
                for iAtlas = indx
                    R = in.atlases.fv{iAtlas,1};
                    
                    name = in.atlases.names{iAtlas};
                    color = in.atlases.colormap(round(in.atlases.colors(iAtlas)),:);
                    try
                        meshR = Mesh(R.faces,R.vertices);
                    catch
                        waitfor(msgbox('Your version of lead-dbs has a known issue with atlases. You can try the [cracked] version at the bottom of the list','lead-dbs error','error'))
                        return
                    end
                    actorR = meshR.see(thisScene);
                    actorR.changeSetting('complexity',5,...
                        'colorFace',color,...
                        'colorEdge',color);
                    
                    
                    
                    try
                        L = in.atlases.fv{iAtlas,2};
                        meshL = Mesh(L.faces,L.vertices);
                        actorL = meshL.see(thisScene);
                        actorL.changeName([name,' left'])
                        actorL.changeSetting('complexity',5,...
                            'colorFace',color,...
                            'colorEdge',color);
                    catch
                        disp('unilateral?')
                        
                        
                    end
                    actorR.changeName([name,' right'])
                end
                
                
                
            end
            
            function menu_legacyatlas(hObject,eventdata)
                %switch state
                rootdir = fileparts(fileparts(mfilename('fullpath')));
                legacypath = fullfile(rootdir,'Elements','SureTune');
                thisScene = ArenaScene.getscenedata(hObject);
                %T = load('Tapproved.mat'); %--> changed feb 24 2022, after
                %call with Andy. 
                T = load('T2022.mat');
                
                
                
                switch hObject.Text
                    case 'STN'
                        obj_stn = ObjFile(fullfile(legacypath,'LH_STN-ON-pmMR.obj'));
                        obj_rn = ObjFile(fullfile(legacypath,'LH_RU-ON-pmMR.obj'));
                        obj_sn = ObjFile(fullfile(legacypath,'LH_SN-ON-pmMR.obj'));
%                         
                        obj_stn_left = obj_stn.transform(T.stu2mni_leftSTN);
                        obj_stn_right = obj_stn.transform(T.stu2mni_rightSTN);
                        obj_rn_left = obj_rn.transform(T.stu2mni_leftSTN);
                        obj_rn_right = obj_rn.transform(T.stu2mni_rightSTN);
                        obj_sn_left = obj_sn.transform(T.stu2mni_leftSTN);
                        obj_sn_right = obj_sn.transform(T.stu2mni_rightSTN);
                        
%                         obj_stn_left = obj_stn.transform(T.leftstn2mni);
%                         obj_stn_right = obj_stn.transform(T.rightstn2mni);
%                         obj_rn_left = obj_rn.transform(T.leftstn2mni);
%                         obj_rn_right = obj_rn.transform(T.rightstn2mni);
%                         obj_sn_left = obj_sn.transform(T.leftstn2mni);
%                         obj_sn_right = obj_sn.transform(T.rightstn2mni);
                        
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
                        
                        
                        thisScene.handles.atlas.legacy.Actor_stnleft.changeName('[mni] STNleft')
                        thisScene.handles.atlas.legacy.Actor_snleft.changeName('[mni] SNleft')
                        thisScene.handles.atlas.legacy.Actor_rnleft.changeName('[mni] RNleft')
                        thisScene.handles.atlas.legacy.Actor_stnright.changeName('[mni] STNright')
                        thisScene.handles.atlas.legacy.Actor_snright.changeName('[mni] SNright')
                        thisScene.handles.atlas.legacy.Actor_rnright.changeName('[mni] RNright')
                        
                    case 'GPi'
                        obj_gpi = ObjFile(fullfile(legacypath,'LH_IGP-ON-pmMR.obj'));
                        obj_gpe = ObjFile(fullfile(legacypath,'LH_EGP-ON-pmMR.obj'));
%                         
                        obj_gpi_left = obj_gpi.transform(T.stu2mni_leftGPI);
                        obj_gpe_left = obj_gpe.transform(T.stu2mni_leftGPI);
                        obj_gpi_right = obj_gpi.transform(T.stu2mni_rightGPI);
                        obj_gpe_right = obj_gpe.transform(T.stu2mni_rightGPI);
                        
%                         obj_gpi_left = obj_gpi.transform(T.leftgpi2mni);
%                         obj_gpe_left = obj_gpe.transform(T.leftgpi2mni);
%                         obj_gpi_right = obj_gpi.transform(T.rightgpi2mni);
%                         obj_gpe_right = obj_gpe.transform(T.rightgpi2mni);
                        
                        [thisScene.handles.atlas.legacy.Actor_gpileft,scene] = obj_gpi_left.see(thisScene);
                        [thisScene.handles.atlas.legacy.Actor_gpeleft,scene] = obj_gpe_left.see(thisScene);
                        [thisScene.handles.atlas.legacy.Actor_gpiright,scene] = obj_gpi_right.see(thisScene);
                        [thisScene.handles.atlas.legacy.Actor_gperight,scene] = obj_gpe_right.see(thisScene);
                        
                        
                        
                        thisScene.handles.atlas.legacy.Actor_gpileft.changeSetting('colorFace',[0 0 1],'faceOpacity',20,'edgeOpacity',0,'complexity',10)
                        thisScene.handles.atlas.legacy.Actor_gpeleft.changeSetting('colorFace',[0 1 1],'faceOpacity',20,'edgeOpacity',0,'complexity',10)
                        thisScene.handles.atlas.legacy.Actor_gpiright.changeSetting('colorFace',[0 0 1],'faceOpacity',20,'edgeOpacity',0,'complexity',10)
                        thisScene.handles.atlas.legacy.Actor_gperight.changeSetting('colorFace',[0 1 1],'faceOpacity',20,'edgeOpacity',0,'complexity',10)
                        
                        thisScene.handles.atlas.legacy.Actor_gpileft.changeName('[mni] GPIleft')
                        thisScene.handles.atlas.legacy.Actor_gpeleft.changeName('[mni] GPEeft')
                        thisScene.handles.atlas.legacy.Actor_gpiright.changeName('[mni] GPIright')
                        thisScene.handles.atlas.legacy.Actor_gperight.changeName('[mni] GPRright')
                        
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
                            
%                             obj_custom_left = obj_custom.transform(T.stu2mni_leftSTN);
%                             obj_custom_right = obj_custom.transform(T.stu2mni_rightSTN);
                            [thisScene.handles.atlas.legacy.(['Actor_obj_custom_',num2str(iAtlas),'_left'])] = obj_custom_left.see(thisScene);
                            [thisScene.handles.atlas.legacy.(['Actor_obj_custom_',num2str(iAtlas),'_right'])] = obj_custom_right.see(thisScene);
                            
                            
                            thisScene.handles.atlas.legacy.(['Actor_obj_custom_',num2str(iAtlas),'_left']).changeSetting('colorFace',[0.5 0.5 0.5],'faceOpacity',20,'edgeOpacity',0,'complexity',10)
                            thisScene.handles.atlas.legacy.(['Actor_obj_custom_',num2str(iAtlas),'_right']).changeSetting('colorFace',[0.5 0.5 0.5],'faceOpacity',20,'edgeOpacity',0,'complexity',10)
                            
                            
                            thisScene.handles.atlas.legacy.(['Actor_obj_custom_',num2str(iAtlas),'_left']).changeName(['[legacy] ',atlases{iAtlas},' left'])
                            thisScene.handles.atlas.legacy.(['Actor_obj_custom_',num2str(iAtlas),'_right']).changeName(['[legacy] ',atlases{iAtlas},' right'])
                        end
                        
                        
                        
                end
                
                
                
                
                
                
            end
            
            function importExcel(thisScene,filename)
                table = readtable(filename);
                try table.amplitude
                catch
                    disp('Only excepts "recipe" files')
                    return
                end
                
                electrodeorcontact = questdlg('Visualize the electrode,the active contact or VTAs?','Arena load recipe','Full electrode','Active contacts','VTAs','Active contacts');
                if isempty(electrodeorcontact);return;end
                mirrortoleft = questdlg('Mirror all electrodes to the left side?','Arena load recipe','Yes','No','Yes');
                if isempty(mirrortoleft);return;end
                
                switch electrodeorcontact
                    case {'Active contacts','VTAs'}
                        [indx] = listdlg('PromptString','Weight based on:','ListString',[table.Properties.VariableNames(21:end),{'no weight'}]);
                        try
                            weightlabel = table.Properties.VariableNames{20+indx};
                        catch
                            weightlabel = nan;
                        end
                end
                  
                ActiveContacts_pc = PointCloud;
                for iRow = 1:length(table.amplitude)
                    try
                        Ttolegacy = eval(table.Tlead2MNI{iRow});
                    catch
                        disp('Reached empty line')
                        break
                    end
                    
                    %T2022 = load('T2022.mat');
                    %TtoMNI = T2022.(['stu2mni_',table.hemisphere{iRow},upper(table.target{iRow})]);


                    cathode = str2num(table.activecontact{iRow});
                    leadname = [table.id{iRow},'_',table.leadname{iRow}];
                    
                    T = Ttolegacy*[-1 0 0 0;0 -1 0 0;0 0 1 0;0 -37.5 0 1]; %to real MNI
                    %T = Ttolegacy*TtoMNI;
                    [modified,T] = A_rigidT(T);

                    
                    
                    e = Electrode;
                    c0 = SDK_transform3d([0 0 0],T);
                    c3 = SDK_transform3d([0 0 6],T);

                    
                    switch mirrortoleft
                        case 'Yes'
                            c0(1) = abs(c0(1))*-1;
                            c3(1) = abs(c3(1))*-1;
                    end
                        
                
                e.Direction = Vector3D(c3-c0).unit.getArray';
                e.C0 = c0;
                e.Type = table.leadtype{iRow};
                    
                    switch electrodeorcontact
                        case 'Full electrode'
                            actor = e.see(thisScene);
                            actor.changeSetting('cathode',cathode);
                            %actor.transform(thisScene,'Fake2MNI')
                            actor.changeName(leadname)
                        case 'Active contacts'
                           
                           if isnan(weightlabel)
                               weight  = 1;
                           else
                               weight = table.(weightlabel)(iRow);
                           end
                           ActiveContacts_pc.addVectors(e.getLocationOfAC(cathode),weight);
                        case 'VTAs'
                            if isnan(weightlabel)
                               weight  = 1;
                           else
                               weight = table.(weightlabel)(iRow);
                           end
                             vtaname = VTA.constructVTAname(table.leadtype{iRow},...
                                 table.amplitude(iRow),...
                                 table.pulsewidth(iRow),...
                                  table.activecontact{iRow},...
                                  table.groundedcontact{iRow},...
                                   table.voltage{iRow});
                                  
                                  
                      vta = e.makeVTA(vtaname);
                             actor = vta.see(thisScene);
                             actor.Meta.(weightlabel) = weight;
                             
                             vtaname = [table.name{iRow},'_',table.leadname{iRow}];
                             actor.changeName(vtaname)
                             
                             
                            
                    end
                end
                
                switch electrodeorcontact
                    case 'Active contacts'
                         ActiveContacts_pc.see(thisScene);
                end
            end
            
            function import_vtk(thisScene,filename,fibers_visual)
                disp('loading a VTK with a custom script. (debug: ArenaScene / import_vtk)')
                fid = fopen(filename);
                tline = fgetl(fid);
                V = [];
                Fib = {};
                %read the file:
                    while ischar(tline)
                       nums = str2num(tline);
                            if length(nums)==3 %3D coordinate
                                   V(end+1,:) = nums;
                            elseif length(nums)==0 %Text
                                    disp(tline)
                            elseif length(nums)==nums(1)+1 %Fiber
                                    Fib{end+1} = nums(2:end)+1;
                            end
                            tline = fgetl(fid);
                    end
                    fclose(fid);
                    %show the fibers
                    f = Fibers;
                    
                    if nargin == 2
                            %dialog box
                            prompt = {['You are loading a VTK file with ',num2str(numel(Fib)),' elements. How many do you want to visualize?'] };
                            dlgtitle = 'Arena VTK loader';
                            definput = {num2str(min([100, numel(Fib)]))};
                            dims = [1 40];
                            opts.Interpreter = 'tex';
                            answer = inputdlg(prompt,dlgtitle,dims,definput,opts);
                            fibers_visual = str2num(answer{1});
                    elseif strcmp(fibers_visual,'all')
                            fibers_visual = numel(Fib);
                    elseif strcmp(fibers_visual,'some')
                            fibers_visual = numel(Fib)/5;
                    end
                    
                    for i = 1:numel(Fib)
                        points = V(Fib{i},:);
                        pc = points;
                        f.addFiber(pc,i);
                    end
                    
                    actor = f.see(thisScene,fibers_visual);
                    [pn,fn] = fileparts(filename);
                    actor.changeName(fn);

                
            end
            
            function import_leadDBSfibers(thisScene,loaded)
                f_left = Fibers;
                f_right = Fibers;
                for iFib = 1:numel(loaded.fibcell{1})
                    f_right.addFiber(loaded.fibcell{1}{iFib},iFib,loaded.vals{1}(iFib));
                end
                for iFib = 1:numel(loaded.fibcell{2})
                    f_left.addFiber(loaded.fibcell{2}{iFib},iFib,loaded.vals{2}(iFib));
                end
                
                h_right = f_right.see(thisScene);
                h_right.changeName(['Fibers (',num2str(numel(loaded.fibcell{1})),')'])
                h_left = f_left.see(thisScene);
                h_left.changeName(['Fibers (',num2str(numel(loaded.fibcell{2})),')'])
                
                h_right.changeSetting('colorFace2',loaded.fibcolor(1,:),'colorFace',loaded.fibcolor(2,:),'colorByDirection',0,'colorByWeight',1)
                h_left.changeSetting('colorFace2',loaded.fibcolor(1,:),'colorFace',loaded.fibcolor(2,:),'colorByDirection',0,'colorByWeight',1)
            
                
                
            end
            
            function import_mat(thisScene,filename)

                loaded = load(filename);
                
                if isfield(loaded,'fibcell')
                    import_leadDBSfibers(thisScene,loaded)
                    return
                end
                
                
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
            
            
            
            function menu_importfromworkspace(hObject,eventdata)
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
                                data{end+1} = PointCloud(thisVariable);
                            end
                        case 'ArenaScene'
                            continue
                        otherwise   
                            names{end+1} = basevariables(iVariable).name;
                            data{end+1} = thisVariable;
                    
                    end
                end
                
                if isempty(names)
                    waitfor(msgbox('No usuable workspace variables could be found!'))
                    return
                end
                
                [indx] = listdlg('ListString',names);
                for index = indx
                   this = data{index};
                   switch class(data{index})
                       case 'VoxelData'
                           if this.isBinary(80)
                               actor = this.getmesh.see(thisScene);
                           else
                               actor = this.getslice.see(thisScene);
                           end
                       otherwise
                           try
                               actor = this.see(thisScene);
                           catch
                               disp(['Don''t know how to load ',names{index}])
                               continue
                           end
                   end
                        actor.changeName(names{index})
                    
                    
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
            
            function import_leadfromnii(scene,v,name)
                Points = v.detectPoints;
                
                answer = questdlg('This file looks like it might contain an electrode.','Arena importer','Yes, import as an electrode','No, this is an image','No, this is an image');
                
                switch answer
                    case 'No, this is an image'
                        [actor] = v.getmesh.see(scene);
                        actor.changeName(name)
                        
                    otherwise
                        [~,order] = sort([Points.z]);% From lowest to highest
                        direction = (Points(order(2))-Points(order(1)));
                        e = Electrode(Points(order(1)),direction.unit);
                        [actor] = e.see(scene);
                        actor.changeName(name);
                end
            end
            
            function menu_importAnything(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                if ispc
                    [filename,pathname] = uigetfile({'*.nii','nifti files (*.nii)';...
                        '*.obj','3d object files (*.obj)';...
                        '*.swtspt','sweetspots (*.swtspt)';...
                        '*.scn','scenes (*.scn)';...
                        '*.mat','matlab data (*.mat)';....
                        '*.xls*','recipe(*.xls)'},...
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
                            if v.isProbablyAMesh
                                
%                              [pointlist] = v.detectPoints();
%                                 if length(pointlist)==2
%                                     import_leadfromnii(scene,v,name)
%                                 else
                                
                                [~,nii_mesh_threshold] = import_nii_mesh(scene,v,name,nii_mesh_threshold);
                                %end
                            else
                                    %check if it has two dots
%                                 [pointlist] = v.detectPoints();
%                                 if length(pointlist)==2
%                                     import_leadfromnii(scene,v,name)
%                                 else
                                import_nii_plane(scene,v,name);
                                %end
                            end
                            
                        case '.obj'
                            import_obj(scene,fullfile(pathname,filename{iFile}))
                        case '.scn'
                            import_scn(scene,fullfile(pathname,filename{iFile}))
                        case '.mat'
                            import_mat(scene,fullfile(pathname,filename{iFile}))
                        case '.swtspt'
                            A_loadsweetspot(scene,fullfile(pathname,filename{iFile}));
                        case '.dcm'
                            addSuretuneSession(scene,fullfile(pathname,filename{iFile}))
                        case '.xlsx'
                            importExcel(scene,fullfile(pathname,filename{iFile}));
                        case '.vtk'
                            import_vtk(scene,fullfile(pathname,filename{iFile}))
                        case '.heatmap'
                            A_loadheatmap(scene,fullfile(pathname,filename{iFile}));
                            
                            
                            
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
            
            function menu_updateVTAlist(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                 %delete all menu items
                 
                if isfield(scene.handles.menu.vtas.list,'main')
                    for i = 1:numel(scene.handles.menu.vtas.list)
                        fns = fieldnames(scene.handles.menu.vtas.list(i));
                        for fn = 1:numel(fns)
                            delete(scene.handles.menu.vtas.list(i).(fns{fn}))
                        end
                    end
                end
                scene.handles.menu.vtas.list = [];
                
                if isfield(scene.handles.menu.vtas.therapylist,'main')
                    for i = 1:numel(scene.handles.menu.vtas.therapylist)
                        fns = fieldnames(scene.handles.menu.vtas.therapylist(i));
                        for fn = 1:numel(fns)
                            try
                            delete(scene.handles.menu.vtas.therapylist(i).(fns{fn}))
                            catch
                                %it cant delete structures.. but doesn't
                                %cause trouble. -JR
                            end
                        end
                    end
                end
                scene.handles.menu.vtas.therapylist = [];
                
                %rebuild all VTA items
                i =0;
                for i = 1:numel(scene.VTAstorage)
                    n = length(scene.handles.menu.vtas.list)+1;
                    scene.handles.menu.vtas.list(n).main = uimenu(scene.handles.menu.vtas.main,'Text',scene.VTAstorage(i).Tag);%,'callback',{@menu_vta,scene.VTAstorage(i)});
                    scene.handles.menu.vtas.list(n).edit = uimenu(scene.handles.menu.vtas.list(n).main,'Text','prediction (unilateral)','callback',{@menu_vta_prediction,scene.VTAstorage(i)});
                    scene.handles.menu.vtas.list(n).review = uimenu(scene.handles.menu.vtas.list(n).main,'Text','Monopolar review (unilateral)','callback',{@menu_vta_review,scene.VTAstorage(i)});
                    scene.handles.menu.vtas.list(n).rename = uimenu(scene.handles.menu.vtas.list(n).main,'Text','Rename','callback',{@menu_vta_rename,scene.VTAstorage(i)});
                    scene.handles.menu.vtas.list(n).show = uimenu(scene.handles.menu.vtas.list(n).main,'Text','Show in Scene','callback',{@menu_vta_show,scene.VTAstorage(i)});
                    scene.handles.menu.vtas.list(n).delete = uimenu(scene.handles.menu.vtas.list(n).main,'Text','Delete from this list','callback',{@menu_vta_delete,scene.VTAstorage(i)});
                end
                scene.handles.menu.vtas.constructtherapy.Enable = 'off';
%                 scene.handles.menu.vtas.batchprediction.main.Enable='off';
                if i>0
                    scene.handles.menu.vtas.list(1).main.Separator = 'on';
                    scene.handles.menu.vtas.constructtherapy.Enable = 'on';
                    scene.handles.menu.vtas.batchprediction.main.Enable='on';
                    scene.handles.menu.vtas.batchprediction.electrodes.Enable='on';
                end
                 if i>2
                    scene.handles.menu.vtas.batchprediction.main.Enable='on';
                    scene.handles.menu.vtas.batchprediction.bilateraltherapy.Enable='on';
                end
                
                %rebuild all Therapy items
                i = 0;
                for i = 1:numel(scene.Therapystorage)
                    n = length(scene.handles.menu.vtas.therapylist)+1;
                    scene.handles.menu.vtas.therapylist(n).main = uimenu(scene.handles.menu.vtas.main,'Text',scene.Therapystorage(i).Tag);%,'callback',{@menu_vta,scene.VTAstorage(i)});
                    if numel(scene.Therapystorage(i).VTAs)>1
                        unibi = 'bi';
                    else
                        unibi = 'uni';
                    end
                    %show buttons for prediction
                     scene.handles.menu.vtas.therapylist(n).predictions = uimenu(scene.handles.menu.vtas.therapylist(n).main,'Text',['run prediction (',unibi,'lateral)'],'callback',{@menu_therapy_prediction,scene.Therapystorage(i)});
                     for iPrediction = 1:numel(scene.Therapystorage(n).Predictions)
                         if iPrediction==1
                         scene.handles.menu.vtas.therapylist(n).predictionlist.main = uimenu(scene.handles.menu.vtas.therapylist(n).main,'Text','Show details for prediction:');
                         end
                         p = scene.Therapystorage(n).Predictions(iPrediction);
                         buttontext = [p.Model.Tag,': ',num2str(p.Output)];
                         scene.handles.menu.vtas.therapylist(n).predictionlist.p(iPrediction) = uimenu(scene.handles.menu.vtas.therapylist(n).predictionlist.main,'Text',buttontext,'callback',{@menu_therapy_showinfo,p});
                     end
                     
                     %show buttons for review
                     scene.handles.menu.vtas.therapylist(n).monopolar = uimenu(scene.handles.menu.vtas.therapylist(n).main,'Text',['run monopolar review (',unibi,'lateral)'],'callback',{@menu_therapy_review,scene.Therapystorage(i)});
                     for iReview = 1:numel(scene.Therapystorage(n).ReviewOutcome)
                         if iReview==1
                             scene.handles.menu.vtas.therapylist(n).reviewlistlist.main = uimenu(scene.handles.menu.vtas.therapylist(n).main,'Text','Show details for Review:');
                         end
                         p = scene.Therapystorage(n).ReviewOutcome(iReview);
                         buttontext = [p.Model.Tag,': ',num2str(p.Output), '  (Conf: ',num2str(round(p.Confidence*100)),'%)'];
                         scene.handles.menu.vtas.therapylist(n).reviewlistlist.p(iPrediction) = uimenu(scene.handles.menu.vtas.therapylist(n).reviewlistlist.main,'Text',buttontext,'callback',{@menu_therapy_see,p});
                     end

                     
                end
                if i>0
                    scene.handles.menu.vtas.therapylist(1).main.Separator = 'on';
                end
                
                
            end
            
            function menu_therapy_showinfo(hObject,eventdata,prediction)
                prediction.printInfo()
            end
            
            function menu_therapy_see(hObject,eventdata,prediction)
                for iVTA = 1:length(prediction.Input.VTAs)
                    actor = prediction.Input.VTAs(iVTA).see(obj);
                    actor.changeName(hObject.Text)
                end
                
            end
                
            
            function menu_vta_prediction(hObject,eventdata,vta)
                p = vta.prediction();
                p.printInfo()
            end
            
            function menu_vta_show(hObject,eventdata,vta)
                vta.see(obj);
            end
            
            function menu_vta_rename(hObject,eventdata,vta)
                customname = newid({'new host name: '},'Arena',1,{vta.Tag});
                vta.Tag = customname{1};
            end
            
            
            function menu_vta_delete(hObject,eventdata,vta)
                indx = find(obj.VTAstorage==vta);
                obj.VTAstorage(indx(1)) = [];
                
            end
            
            function menu_vta_review(hObject,eventdata,vta)
                vta.review()
            end
            
            function menu_therapy_prediction(hObject,eventdata,therapy)
                p= therapy.executePrediction();
                p.printInfo()
                
            end
            
            function menu_therapy_review(hObject,eventdata,therapy)
                therapyObject = therapy.executeReview();
                assignin('base','T',therapyObject);
            end
            
            function menu_constructTherapy(hObject,eventdata)
                %select VTAs
                VTAnames = {obj.VTAstorage.Tag};
                if isempty(VTAnames)
                    return
                end
                [indx] = listdlg('ListString',VTAnames,'PromptString','Select the VTAs');
                
                %choose name
                nameparts = strsplit(VTAnames{indx(1)},' ');
                
                %Build therapy object
                therapyname = newid({'Therapy name: '},'Arena',1,nameparts(1));
                T = Therapy(therapyname{1});
                T.addVTA(obj.VTAstorage(indx))
                T.connectTo(obj)
            end
            
            function menu_placeElectrode(hObject,eventdata)
                msgbox('Please follow instructions in the MATLAB command window')
                new_lead = Electrode;
                assignin('base','new_lead',new_lead)
                assignin('base','scene',obj)
                home;
                disp('Specify the tip of the lead (C0), and either the direction or a point on the lead.')
                disp('use: ')
                disp('- new_lead.C0 = .... ')
                disp('- new_lead.Direction = .... ')
                disp('- new_lead.PointOnLead = .... ')
                disp('Show in your scene using: new_lead.see(scene)')
            end
            
            function menu_runbatch_electrodes(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                if numel(scene.VTAstorage)<2
                    error('for batch review, at least two electrodes/VTAs are needed');
                    return
                end
                for ii=1:numel(scene.VTAstorage)
                    menu_vta_review(hObject,eventdata, scene.VTAstorage(ii));
                    
                end
                    
                    
                    
%                    menu_vta_review,scene.VTAstorage(i)}
                  
            end
            
            function menu_runbatch_bilateraltherapy(hObject,eventdata)
                if numel(scene.Therapystorage)<2
                    error('for batch review, at least two electrodes/VTAs are needed');
                    
                end
                %ask for settings once:
                UserChoices = Therapy.UserInputModule();
                
                
                 for iTherapy=1:numel(scene.Therapystorage)
                     therapyObject = scene.Therapystorage(iTherapy);
                     therapyObject.executeReview(UserChoices)
                      assignin('base',['Therapy_',num2str(iTherapy)],therapyObject);
                 end
                
%                     menu_therapy_prediction(hObject,eventdata,scene.Therapystorage(iTherapy))
%                      for jj=1:numel(scene.Therapystorage.VTAs(jj))
%                      menu_vta_review(hObject,eventdata,scene.Therapystorage.VTAs(jj));
%                      end
                    
                
                
                
                
            end
            
           
            function menu_generateVTA(hObject,eventdata)
                %ask for electrode
                if numel(obj.Actors)==0
                    disp('requires a "Electrode" actor')
                    return
                else
                    classes = arrayfun(@(x) class(x.Data), obj.Actors,'UniformOutput',0);
                    VTAobjects = strcat(classes,{'  : '},{obj.Actors.Tag});
                    layerids = 1:length(classes);
                    onlyLead = contains(classes,'Electrode');
                    VTAobjects = VTAobjects(onlyLead);
                    layerids  = layerids(onlyLead);
                end
                
                if sum(onlyLead)==0
                    return
                end

                [indx] = listdlg('ListString',VTAobjects,'PromptString','Select the Electrode','ListSize',[300 160],'SelectionMode','single');
                
                E_actor = obj.Actors(layerids(indx));
                E = E_actor.Data;

                
                %ask for settings:
                vtasettings = inputdlg({'Cathodes [c0 c1 c2 c3]',...
                'Anodes [c0 c1 c2 c3]',...
                'Amplitude (mA)',...
                'PulseWidth (us)'},...
                'Settings',...
                1,...
                {'1 0 0 0','0 0 0 0','1','90'});
            
                vtaname = VTA.constructVTAname('Medtronic3389',str2double(vtasettings{3}),str2double(vtasettings{4}),vtasettings{1},vtasettings{2},'False');
                try
                VTAObject = makeVTA(E,vtaname);
                catch
                    warning ('on','all');
                    warning('VTA not available in pool')
                    return
                end
                
                %Ask for Space
                VTAObject.Space = Space.dialog('In which space is this electrode Currently?');
               
                VTAObject.Tag = [E_actor.Tag,' C',num2str(find(str2num(vtasettings{1}))-1),' ',vtasettings{3},'mA (',vtasettings{4},'us)'];
                VTAObject.connectTo(obj)
                VTAObject.ActorElectrode = E_actor;
                actor = VTAObject.see(obj);
                VTAObject.ActorVolume = actor;
                
                   
            
            
                
            end
            
            function menu_constructVTA(hObject,eventdata)
                %this function will make it possible to convert any data
                %source to a VTA object (for instance nii files)
                if numel(obj.Actors)==0
                    VTAobjects = {};
                else
                    classes = arrayfun(@(x) class(x.Data), obj.Actors,'UniformOutput',0);
                    VTAobjects = strcat(classes,{'  : '},{obj.Actors.Tag});
                end
                VTAobjects{end+1} = '..Load';
                    
                [indx] = listdlg('ListString',VTAobjects,'PromptString','Select the VTA and/or Electrode that belong together','ListSize',[300 160]);
                
                
                %load new actors
                if indx ==length(VTAobjects)
                    nActors = length(obj.Actors);
                    menu_importAnything(hObject,eventdata)
                    if nActors > length(obj.Actors)
                        indx = nActors+1:length(obj.Actors);
                    end
                   
                    classes = arrayfun(@(x) class(x.Data), obj.Actors,'UniformOutput',0);
                end
                
            
                
                %checking for senseless combination. 
                if length(unique(classes(indx)))<length(indx)
                    error('It looks like you selected a strange combination. Select only one VTA at a time. (may include both mesh and electrode object)')
                end
                
                
                thisVTA = VTA;
                for i = indx
                    switch classes{i}
                        case 'Electrode'
                            thisVTA.ActorElectrode = obj.Actors(i);
                            thisVTA.Electrode= obj.Actors(i).Data;
                        case 'Mesh'
                            thisVTA.ActorVolume = obj.Actors(i);
                            thisVTA.Volume= obj.Actors(i).Data;
                    end
                end
                
                %check space
                thisVTA.Space = Space.dialog('Which space is your VTA in?');
                if thisVTA.Space == Space.Unknown
                    waitfor(msgbox('If the space is unknown, prediction models will not be very helpful. :-)'))
                end
                
                % 
                VTAname = newid({'VTA name: '},'Arena',1,{obj.Actors(indx(1)).Tag});
                thisVTA.Tag = VTAname{1};
                thisVTA.connectTo(obj)
                
                
            end

            
                
            function menu_vta(hObject,eventdata,vta)
                keyboard
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
                scene = ArenaScene.getscenedata(hObject);
                currentActors = ArenaScene.getSelectedActors(scene);
                actorNames = {currentActors.Tag};
                shortestName = min(cellfun(@length, actorNames));
                
                
                vd = ArenaScene.countMesh(hObject);
                actor = vd.getmesh.see(ArenaScene.getscenedata(hObject));
                
                %change name
                incommon = '';
                for iLetter = 1:shortestName
                    
                    letter = unique(cellfun(@(x) x(iLetter),actorNames));
                    if length(letter)==1
                        incommon = [incommon,letter];
                    else
                        break
                    end
                end
                actor.changeName(incommon)
                changeLayerName(hObject,eventdata)
                
   
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
                    voxels = thisActor.Data.parent.Voxels;
                    
                end
                
                
            end
            
            function menu_extractLeadFromCT(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                currentActors = ArenaScene.getSelectedActors(scene);
                
                for iActor = 1:numel(currentActors)
                    thisActor = currentActors(iActor);
                    
                    vd = thisActor.Data.parent;
                    Voxels = vd.Voxels;
                    
                    skull = Voxels > 700;
                    cables = Voxels > 2000;
                    
                    %get COG of skull
                    indxskull = find(skull);
                    [x,y,z] = ind2sub(size(skull),indxskull);
                    cog_head_imagespace = [mean(x),mean(y),mean(z)];
                    
                    %get tips in image space
                    skeleton = bwskel(cables);
                    indxtips = find(bwmorph3(skeleton,'endpoints'));
                    [xtips,ytips,ztips] = ind2sub(size(cables),indxtips);
                    
                    tips = [xtips,ytips,ztips];
                    distances = sum(abs(tips-cog_head_imagespace),2);
                    
                    [b,i] = sort(distances,'ascend');
                    tip1 = tips(i(1),:);
                    tip2 = tips(i(2),:);
                    
                    %tips in worldspace
                    [t1x,t1y,t1z] = vd.R.intrinsicToWorld(tip1(2),tip1(1),tip1(3));
                    [t2x,t2y,t2z] = vd.R.intrinsicToWorld(tip2(2),tip2(1),tip2(3));
                    
                    e1 = Electrode;
                    e1.C0 = Vector3D([t1x,t1y,t1z]);
                    
                    
                    e2 = Electrode;
                    e2.C0 = Vector3D([t2x,t2y,t2z]);
          
                    
                    %
                    [skeletonpointsX,skeletonpointsY,skeletonpointsZ] = ind2sub(size(skeleton),find(skeleton));
                    skeletonpoints = [skeletonpointsX,skeletonpointsY,skeletonpointsZ];
                    
                    %e1
                    step = makeStepFrom(skeletonpoints,tip1,10);
                    step = makeStepFrom(skeletonpoints,step,10);
                    [pol1,pol2,pol3] = vd.R.intrinsicToWorld(step(2),step(1),step(3));
                    
                    e1.PointOnLead(Vector3D([pol1,pol2,pol3]))
                    e1.C0 = e1.C0+e1.Direction/2;
                    e1.see(scene)
                    
                    %e2
                    step = makeStepFrom(skeletonpoints,tip2,10);
                    step = makeStepFrom(skeletonpoints,step,10);
                    [pol1,pol2,pol3] = vd.R.intrinsicToWorld(step(2),step(1),step(3));
                   
                    e2.PointOnLead(Vector3D([pol1,pol2,pol3]))
                    e2.C0 = e2.C0+e2.Direction/2;
                    e2.see(scene)
                    
                    
                    
                   
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                end
                 function point = makeStepFrom(skeletonpoints,from,l)
                        %never walk down
                        height = skeletonpoints(:,3);
                        height(height < from(3)) = inf;
                        skeletonpoints(:,3) =  height;
                        %--

                        d = sum(abs(skeletonpoints-from),2);
                        search = abs(d-l);
                        point = skeletonpoints(search==min(search),:);
                        
                    end
                
            end
            
            
            
            function menu_applyMask(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                currentActors = ArenaScene.getSelectedActors(scene);
                
                [~,meshcandidate_name,meshcandidate_indx] = ArenaScene.getActorsOfClass(scene,'Mesh');
                [~,slicecandidate_name,slicecandidate_indx] = ArenaScene.getActorsOfClass(scene,'Slicei');
                
                meshcandidate_name  = cellfun(@(c)['Mesh: ' c],meshcandidate_name,'uni',false);
                slicecandidate_name  = cellfun(@(c)['Slice: ' c],slicecandidate_name,'uni',false);
                
                [indx] = listdlg('ListString',[meshcandidate_name,slicecandidate_name],'PromptString','Select the mask');
                candidate_indx = [meshcandidate_indx,slicecandidate_indx];
                mask_index = candidate_indx(indx);
                
                maskActor = scene.Actors(mask_index);
                map = currentActors.Data.parent;
                
                
                switch class(maskActor.Data)
                    case 'Mesh'
                        if ~isempty(maskActor.Data.Source)
                            maskVD = maskActor.Data.Source.makeBinary(maskActor.Data.Settings.T);
                            maskVD.warpto(map)
                        else
                            maskActor.Data.convertToVoxelsInTemplate(map)
                        end
                    case 'Slicei'
                        maskVD = maskActor.Data.parent.makeBinary;
                        maskVD.warpto(map);
                end
                
                maskVD.Voxels = double(maskVD.Voxels);
                maskVD.Voxels(maskVD.Voxels==0) = nan;
                maskedImage = map.*maskVD;
                actor = maskedImage.getslice.see(scene);
                actor.changeName(['masked_',currentActors.Tag])
                
                
                
                        
                
                
            end
            
            
            
            function menu_smoothslice(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                currentActors = ArenaScene.getSelectedActors(scene);
                for iActor = 1:numel(currentActors)
                    thisActor = currentActors(iActor);
                    cropped = thisActor.Data.parent.convertToCropped;
                    cropped.smooth;
                    actor = cropped.getslice.see(scene);
                    actor.changeName(['Smoothed_',thisActor.Tag])
                end
                
            end
            
            function menu_multiplyslices(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                currentActors = ArenaScene.getSelectedActors(scene);
                
                if not(numel(currentActors)==2)
                    f = msgbox('You need to select 2 slices', 'Error','error');
                    return
                end
                
                %choose the template.

                
                R_1= [currentActors(1).Data.parent.R.XWorldLimits,...
                    currentActors(1).Data.parent.R.YWorldLimits,...
                    currentActors(1).Data.parent.R.ZWorldLimits,...
                    currentActors(1).Data.parent.R.PixelExtentInWorldX,...
                    currentActors(1).Data.parent.R.PixelExtentInWorldY,...
                      currentActors(1).Data.parent.R.PixelExtentInWorldZ];
                  
                  R_2 = [currentActors(2).Data.parent.R.XWorldLimits,...
                    currentActors(2).Data.parent.R.YWorldLimits,...
                    currentActors(2).Data.parent.R.ZWorldLimits,...
                    currentActors(2).Data.parent.R.PixelExtentInWorldX,...
                    currentActors(2).Data.parent.R.PixelExtentInWorldY,...
                      currentActors(2).Data.parent.R.PixelExtentInWorldZ];
                  
                  if not(all(R_1==R_2))
                      [indx] = listdlg('ListString',{currentActors(:).Tag},PromptString','Select the template space:');
                      switch indx
                          case 1
                              img1 = currentActors(1).Data.parent;
                              img2 = currentActors(1).Data.parent.warpto(img1);
                          case 2
                              img2 = currentActors(2).Data.parent;
                              img1 = currentActors(1).Data.parent.warpto(img2);
                      end
                  else
                      img1 = currentActors(1).Data.parent;
                      img2 = currentActors(2).Data.parent;
                  end
                  
                  
                  newimg = img1.*img2;
                  newactor = newimg.getslice.see(scene);
                  newactor.changeName([currentActors(1).Tag,' X ',currentActors(2).Tag])
 
            end
            
            function menu_spatialcorrelation(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                currentActors = ArenaScene.getSelectedActors(scene);
                if numel(currentActors)~=2
                    error('correlation needs two actors to be selected in the layer panel!')
                end
                
                %if 
                
                %check is data contains VoxelData
                VoxelDatas = {};
                for iActor = 1:numel(currentActors)
                    thisActor = currentActors(iActor);
                    switch class(thisActor.Data)
                        case 'Mesh'
                            if isempty(thisActor.Data.Source)
                                error('Data does not contain VoxelData information')
                            end
                            VoxelDatas{iActor} = thisActor.Data.Source;
                            
                        case 'Slicei'
                            VoxelDatas{iActor} = thisActor.Data.parent;
                    end
                end
                 v1  = VoxelDatas{1}.Voxels(:);
                 v2 = VoxelDatas{2}.warpto(VoxelDatas{1}).Voxels(:);
                 nans = or(isnan(v1),isnan(v2));
                 v1(nans)=[];
                 v2(nans)= [];
                 if any(nans)
                    disp(['NaNs were removed from analysis (',num2str(round(mean(nans)*100),3),'%)'])
                 end
                
                 
                 [pearson_r,pearson_p] = corr(v1,v2);
                 [spearman_r,spearman_p] = corr(v1,v2,'Type','Spearman');
                disp(['Pearson correlation: ',num2str(pearson_r),' (correlation P-value: ',num2str(pearson_p),')']);
                disp(['Spearman correlation: ',num2str(spearman_r),' (correlation P-value: ',num2str(spearman_p),')']);

disp('Pearson checks if it is on a line while spearman checks if they move in a same direction.')
disp('Therefore pearson is more conservative. If your data is ordinal: do not use pearson but spearman.')
                
                
                
                    
                                
                
                
                
            end
            
            function menu_mesh2binaryslice(hObject,eventdata)
                 scene = ArenaScene.getscenedata(hObject);
                currentActors = ArenaScene.getSelectedActors(scene);
                
                
                binaryvd = currentActors(1).Data.Source.makeBinary(currentActors(1).Data.Settings.T);
                binaryvd.getslice.see(scene)
                
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
                
                
                disp(results)
                
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
                        b(iB).FaceColor = [1 1 1];
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
            
            function menu_burnPointCloudIntoVoxelData(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                currentActors = ArenaScene.getSelectedActors(scene);
                
                actorNames = {scene.Actors.Tag};
                sliceiNames = {};
                nr = [];
                for i = 1:numel(actorNames)
                    switch class(scene.Actors(i).Data)
                        case 'Slicei'
                            sliceiNames{end+1} = actorNames{i};
                            nr(end+1) = i;
                    end
                end
                
                %select template
                [indx,tf] = listdlg('PromptString','Select Template to project to','ListString',sliceiNames);
                
                blobsize = newid({'Size of the blobs (mm): '},'Arena',1,{'4'});
                
                %make a copy of that Voxeldata
                temp = scene.Actors(nr(indx)).Data.parent;
               
                
                balls = makeBallMesh(currentActors.Data,str2num(blobsize{1}));
                
                for iball = 1:numel(balls)
                    
                    thisBall = balls{iball};
                    if iball ==1
                       sumVDs = thisBall.convertToVoxelsInTemplate(temp);
                    else
                        sumVDs = sumVDs+thisBall.convertToVoxelsInTemplate(temp);
                    end
                end
                
                

      
                actor = sumVDs.getmesh.see(scene);
                
                
                
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
            
            
            function menu_fiberSummary(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                currentActors = ArenaScene.getSelectedActors(scene);
                
                average = [];
                totalsum = [];
                nonzeropercent = [];
                number = [];
                
                
                [fiberActors,names] = ArenaScene.getActorsOfClass(scene,'Fibers');
                for iFiber = 1:numel(fiberActors)
                    thisFiber = fiberActors(iFiber);
                    number(iFiber,1) = numel(thisFiber.Visualisation.handle);
                    if isempty(thisFiber.Data)
                        average(iFiber,1) = nan;
                        totalsum(iFiber,1) = nan;
                        nonnceroperceernt(iFiber,1) = nan;
                        
                    end
                    average(iFiber,1) = nanmean(thisFiber.Data.Weight);
                    totalsum(iFiber,1) = nansum(thisFiber.Data.Weight);
                    nonzeropercent(iFiber,1) = nnz(thisFiber.Data.Weight)/numel(thisFiber.Data.Weight)*100;
                   
                end
                
                summary = table(names(:),average,totalsum,nonzeropercent,number)
                assignin('base','summary',summary)
                Done;

                
            end
            
            function menu_fibersToROI(hObject,eventdata)
                 scene = ArenaScene.getscenedata(hObject);
                    currentActors = ArenaScene.getSelectedActors(scene);
                    
                    classes = arrayfun(@(x) class(x.Data), scene.Actors,'UniformOutput',0);
                    templateSpace = strcat(classes,{'  : '},{scene.Actors.Tag});
                
                templateSpace{end+1} = '..Load';
                    
                [indx] = listdlg('ListString',templateSpace,'PromptString','Select the template space','ListSize',[300 160]);
                
                if indx==numel(templateSpace)
                    template = VoxelData;
                    template.loadnii;
                else
                    template = scene.Actors(indx).Data;
                    if not(isa(templateSpace,'VoxelData'))
                        try
                            template = template.parent;
                        catch
                            error('Need to select a VoxelData')
                        end
                    end
                end
                    blank = zeros(size(template.Voxels));
                    
                    for iActor = 1:numel(currentActors)
                        %get start and endings
                        thisActor = currentActors(iActor).Data;
                        for iFiber = 1:numel(thisActor.Vertices)
                            thisFiber = thisActor.Vertices(iFiber);
                            first = thisFiber.Vectors(1);
                            last = thisFiber.Vectors(end);
                            [fx,fy,fz] =template.R.worldToSubscript(first.x,first.y,first.z);
                            [lx,ly,lz] =template.R.worldToSubscript(last.x,last.y,last.z);
                            
                            blank(fx,fy,fz) = blank(fx,fy,fz)+1;
                            blank(lx,ly,lz) = blank(lx,ly,lz)+1;
                        end
                     
                        
                    end
                    
                    output = VoxelData(blank,template.R);
                    outputdir = output.saveniidlg;
                    [a,b,c] = fileparts(outputdir);
                    output.makeBinary(0.5).imdilate(1).savenii(fullfile(a,[b,'_dilated_1',c]))
                    output.makeBinary(0.5).imdilate(2).savenii(fullfile(a,[b,'_dilated_2',c]))
                    output.makeBinary(0.5).imdilate(3).savenii(fullfile(a,[b,'_dilated_3',c]))
                    output.makeBinary(0.5).imdilate(4).savenii(fullfile(a,[b,'_dilated_4',c]))
                    output.makeBinary(0.5).imdilate(5).savenii(fullfile(a,[b,'_dilated_5',c]))
                    Done;
                    disp(['file saved at: ',outputdir])
                        
                
                
            end
                
            
            function menu_fiberMapInterference(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                currentActors = ArenaScene.getSelectedActors(scene);
                

                %--> to do: only suggest meshes or slices.
                %get map
                labels = {scene.Actors.Tag};
                [indx,tf] = listdlg('PromptString',{'Select one map'},'ListString',labels);
                

                if isa(scene.Actors(indx).Data,'Mesh')
                    if isempty(scene.Actors(indx).Data.Source)
                        samplingMethod = 'Check if fiber hits mesh';
                        map = [];
                        mesh = scene.Actors(indx).Data;
                    else
                        samplingMethod = 'undecided';
                        map = scene.Actors(indx).Data.Source;
                        mesh = scene.Actors(indx).Data;
                    end
                elseif isa(scene.Actors(indx).Data,'Slicei')
                    samplingMethod = 'only voxelbased';
                    map = scene.Actors(indx).Data.parent;
                    mesh = [];
                else
                    return
                end
                
                %get method
                switch samplingMethod
                    case 'Check if fiber hits mesh'
                        %clear no more options to choose
                    case 'undecided'
                        options = {'Min value','Max value','Average Value','Sum','Check if fiber hits mesh'};
                        [indx,tf] = listdlg('PromptString',{'Select method'},'ListString',options);
                        samplingMethod = options{indx};
                    case 'only voxelbased'
                        options = {'Min value','Max value','Average Value','Sum'};
                        [indx,tf] = listdlg('PromptString',{'Select method'},'ListString',options);
                        samplingMethod = options{indx};
                end
                fiberMapInterference(map,mesh,samplingMethod,currentActors)
            end
            

            function fiberMapInterference(map,mesh,samplingMethod,currentActors) %currentActors == Fibers?, can those be several or 
                
                fibers=cell(numel(currentActors),1);
                average_tract=zeros(numel(currentActors),1);
                median_tract=zeros(numel(currentActors),1);
                percentageofFiber_hit=zeros(numel(currentActors),1);
                
                %save_answer = questdlg('Do you want to export the fiber values to the currently active folder?','save','yes','no','save to custom directory','yes');
                
                %switch save_answer
                  %  case 'yes'
                 %       folder_selected=pwd;
                 %   case 'save to custom directory'
                 %       [folder_selected] = uigetdir;
                        
               % end
                
                 
                for iCurrent=1:numel(currentActors)
                    fibers{iCurrent}=currentActors(iCurrent).Tag;
     
                %loop. First join all the fibers. For quick processing
                nVectorsPerFiber = arrayfun(@(x) length(x.Vectors),currentActors(iCurrent).Data.Vertices);
                Vectors = Vector3D.empty(sum(nVectorsPerFiber),0); %empty allocation
                FiberIndices = [0,cumsum(nVectorsPerFiber)]+1;
                weights = [];
%                 fibIndex = 1;
                for iFiber = 1:numel(currentActors(iCurrent).Data.Vertices)
                    Vectors(FiberIndices(iFiber):FiberIndices(iFiber+1)-1) = currentActors(iCurrent).Data.Vertices(iFiber).Vectors;
                end
                FiberIndices(iFiber+1) = length(Vectors)+1;
                 
                
                %sample the map
                switch samplingMethod
                    case 'Check if fiber hits mesh'
                        mapvalue = mesh.isInside(Vectors);
                    otherwise
                        mapvalue = map.getValueAt(PointCloud(Vectors));
                end
                
             
            
                
                
                for iFiber = 1:numel(currentActors(iCurrent).Data.Vertices)
                    weights = mapvalue(FiberIndices(iFiber):FiberIndices(iFiber+1)-1);
                    
                    switch samplingMethod
                        case 'Min value'
                            currentActors(iCurrent).Data.Weight(iFiber) = min(weights);
%                             TractInterference(iFiber)=min(currentActors.Data.Weight,'omitnan');
                           
                        case {'Max value','Check if fiber hits mesh'}
                            currentActors(iCurrent).Data.Weight(iFiber) = max(weights);
                            
                        case 'Average Value'
                            currentActors(iCurrent).Data.Weight(iFiber) = mean(weights,'omitnan');
                           
                        case 'Sum'
                            currentActors(iCurrent).Data.Weight(iFiber) = nansum(weights); 
                                  
                    end
                end
                
%                 average_tract(iCurrent)=nanmean(weights{iCurrent},'omitnan');
%                 median_tract(iCurrent)=median(weights{iCurrent},'omitnan');
%                 percentageofFiber_hit(iCurrent)=100*(nnz(weights{iCurrent})/numel(weights{iCurrent}));
% %                 FibersHit=num2cell(FibersHit',1);
% %                 T=table(meshes(:),FibersHit{:}, 'VariableNames', {'ROI', fibersLoaded{:}});
                 currentActors(iCurrent).changeSetting('colorByWeight',true);
                 weights = currentActors(iCurrent).Data.Weight;
       %          save(fullfile(folder_selected,[currentActors(iCurrent).Tag,'.mat']),'weights')
                   
                end
                
                
                %Done; 
                
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
                thisConnectome = connectomes.selectConnectome;
                
                for iActor = 1:numel(currentActors)
                    home;
                    tic
                    thisActor = currentActors(iActor);
                    thisFiber = thisConnectome.getFibersPassingThroughMesh(thisActor.Data,N_FIBERS,scene);
                    thisFiber.visualize()
                    %thisFiber.ActorHandle.changeSetting('colorByDirection',0,'colorFace',thisActor.Visualisation.settings.colorFace,'colorFace2',thisActor.Visualisation.settings.colorFace2,'numberOfFibers',N_FIBERS);
                    thisFiber.ActorHandle.changeSetting('numberOfFibers',N_FIBERS);
                    thisFiber.ActorHandle.changeName(['Fibers_through_',thisActor.Tag]);
                    toc
                end
                
            end
            
            
            function menu_showFibers_inbetween(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                currentActors = ArenaScene.getSelectedActors(scene);
                N_FIBERS = 100;
                
                if length(currentActors)~= 2
                    return
                end
                
                global connectomes
                thisConnectome = connectomes.selectConnectome;
                
                Fibers = thisConnectome.getFibersConnectingMeshes({currentActors(1).Data,currentActors(2).Data},N_FIBERS,scene);
                Fibers.visualize()
                Fibers.ActorHandle.changeSetting('numberOfFibers',N_FIBERS);
                Fibers.ActorHandle.changeName(['Fibers connecting ',currentActors(1).Tag(1:min([10,length(currentActors(1).Tag)])), ' and ',currentActors(2).Tag(1:min([10,length(currentActors(2).Tag)]))])
                
                
            end
            
            function menu_addToVTApool(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                currentActors = ArenaScene.getSelectedActors(scene);
                
                for iActor = 1:numel(currentActors)
                    thisActor = currentActors(iActor);
                    A_addToVTApool(thisActor,scene)
                end
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
            
            function menu_detectElectrode(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                currentActors = ArenaScene.getSelectedActors(scene);
                electrode={};
                
                if numel(currentActors)>2
                    disp('please select only two meshes')
                    return
                end
                for iSelectActor=1:numel(currentActors)
                    COG=currentActors(iSelectActor).Data.getCOG;
                    electrode{iSelectActor}=COG;
                end
                if electrode{1}.z> electrode{2}.z
                    tip=electrode{2};
                    PointonLead=electrode{1};
                else
                    tip=electrode{1};
                    PointonLead=electrode{2};
                end
                E=Electrode;
                E.C0=tip;
                E.Direction=PointonLead-tip;
                E.see(scene);
                
                %take vertices
                %apply PCA
                %get the deepest point.
                
            end
            
            function menu_takeSample(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                currentActors = ArenaScene.getSelectedActors(scene);
                selection = listdlg('ListString',{scene.Actors.Tag},'PromptString','Select source to take a bit from:',...
                           'SelectionMode','single');
                if isempty(selection)
                    return
                end
                switch  class(scene.Actors(selection).Data)      
                    case 'Slicei'
                        mapVD = scene.Actors(selection).Data.parent;
                    case 'Mesh'
                        mapVD = scene.Actors(selection).Data.Soure;
                        if isempty(mapVD)
                            error('This mesh does not contain VoxelData')
                        end
                end
                disp('aligning mesh to voxeldata...')
                ROI = currentActors.Data.convertToVoxelsInTemplate(mapVD);
                sample = mapVD.Voxels(ROI.Voxels>0.5);
                assignin('base','sample',sample)
                Done;
                disp('sample is available in workspace as ''sample''')
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
                similarity = array2table(a,'RowNames',labels,'VariableNames',labels);
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
                                
                                cubicMM(iActor,1) = thisActor.Data.getCubicMM;
                                nVoxels(iActor,1) = nan;
                                voxelsize(iActor,1) = nan;
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
            
            function changeLayerName(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                currentActors = ArenaScene.getSelectedActors(scene);
                if numel(currentActors)>1
                    newname = inputdlg('Change prefix','Arena',[1 40],{''});
                    for iActor = 1:numel(currentActors)
                        thisOne = currentActors(iActor);
                        thisOne.Tag = [newname{1},thisOne.Tag];
                    end
                        
                else
                    thisActor = currentActors(1);
                    newname = inputdlg('Change name','Arena',[1 40],{thisActor.Tag});
                    thisActor.Tag = newname{1};
                    scene.refreshLayers();
                end
                scene.refreshLayers();
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
                    try
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
                        case 'radiobutton'
                            settings.(h.Tag) = h.Value;
                        otherwise
                            keyboard
                    end
                    catch
                        %radioboxes do not have "style" and are skipped
                    end
                    
                end
                
            end
            
            
            function keyShortCut(src,eventdata)
                
                
                switch eventdata.EventName
                    case 'WindowMousePress'
                        disp('click')
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
                            case 'leftarrow'
                               STEPSIZE = pi/60;
                                original_pos = campos;
                                original_target = camtarget;
   
                                viewline = Vector3D(original_target - original_pos);
         
                                radAxi = viewline.getAxiAngle;
                                newDirection = Vector3D.setAxiAngle(STEPSIZE+radAxi).getArray';
 
                                viewline.z  = 0;
                                distance = viewline.norm;
                                
                                new_position = original_target + newDirection*distance;
                                new_position(3) = original_pos(3);
                                campos(new_position);
                         
                                
                            case 'rightarrow'
                               STEPSIZE = -pi/60;
                                original_pos = campos;
                                original_target = camtarget;
                                
                                viewline = Vector3D(original_target - original_pos);
         
                                radAxi = viewline.getAxiAngle;
                                newDirection = Vector3D.setAxiAngle(STEPSIZE+radAxi).getArray';
 
                                viewline.z  = 0;
                                distance = viewline.norm;
                                
                                new_position = original_target + newDirection*distance;
                                new_position(3) = original_pos(3);
                                campos(new_position);
                        
                                
                            case 's'
                                if numel(eventdata.Modifier)>2
                                    show_shortcuts(src);
                                end
                            case 'i'
                                if numel(eventdata.Modifier)==1
                          
                                    switch eventdata.Modifier{1}
                                        case {'command','shift'}
                                            menu_importAnything(src)
                                    end
                                    
                                elseif numel(eventdata.Modifier)==2
                                    menu_importfromworkspace(src)
                                    
                                end
                            case 'd'
                                if ~isempty(eventdata.Modifier)
                                    switch eventdata.Modifier{1}
                                        case {'command','shift'}
                                            menu_duplicate(src)
                                    end
                                end
                            case 'return'
                                
                                %check if mouse is hovering the listbox
                                if strcmp(obj.handles.panelright.Visible,'on')
                                    listboxpos = obj.handles.panelright.Position;
                                    currpt = get(obj.handles.figure,'CurrentPoint');
                                    Xinside = currpt(1)>listboxpos(1) && currpt(1) < listboxpos(1)+listboxpos(3);
                                    Yinside = currpt(2)>listboxpos(2) && currpt(2) < listboxpos(2)+listboxpos(4);
                                    if Xinside && Yinside
                                        if not(isempty(obj.Actors))
                                            changeLayerName(src,eventdata)
                                        end
                                    end
                                end
                                
                            case 'b'
                                 set(scene.handles.figure,'Color',1-scene.handles.figure.Color)                                 
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
                    case 'hideall'
                        for iActor = 1:numel(scene.Actors)
                            thisActor = scene.Actors(iActor);
                            thisActor.Visibility('hide');
                        end
                        
                end
                scene.refreshLayers();
                
            end
            
            function setcurrentpointlive(fig,event)
                %this is nothing, but its presence is enough. :-) trust me
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
                try
                    properties = fieldnames(obj.Actors(i).Visualisation.settings);
                    rgbColour = obj.Actors(i).Visualisation.settings.(properties{1})*255;
                    if isfield(obj.Actors(i).Visualisation.settings,'colorFace2') %for fibers
                        rgbColour = obj.Actors(i).Visualisation.settings.colorFace2*255;
                    end
                catch %no visualisation properties exist.
                    rgbColour = [0 0 0];
                end
                
                    
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
                    otherwise
                        functions = fieldnames(obj.handles.menu.dynamic.(thisOtherClass));
                        for iFunction = 1:numel(functions)
                            thisFunction = functions{iFunction};
                            obj.handles.menu.dynamic.(thisOtherClass).(thisFunction).Enable = 'off';
                        end
                end
            end
            for iOther = 1:numel(otherclasses)
                thisOtherClass = otherclasses{iOther};
                switch thisOtherClass
                    case thisclass
                        functions = fieldnames(obj.handles.menu.dynamic.(thisOtherClass));
                        for iFunction = 1:numel(functions)
                            thisFunction = functions{iFunction};
                            obj.handles.menu.dynamic.(thisOtherClass).(thisFunction).Enable = 'on';
                        end
                end
            end
            
        end
        
        function selectlayer(obj,index)
            if nargin==1
                try
                index = obj.handles.panelright.Value(1);
                catch
                   index = 1;
                end
                   
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
            
            heightpxls = 200;
            widthpxls = 500;
            
            xpadding = 0.05*widthpxls;
            ypadding = 0.05*heightpxls;
            
            checkboxwidth = 0.3*widthpxls;
            checkboxheight = 0.1*heightpxls;
            colorwidth = 0.2*widthpxls;
            colorheight = 0.1*heightpxls;
            editheight = 0.1*heightpxls;
            textwidth = 0.15*widthpxls;
            editwidth = 0.2*widthpxls;
            popupwidth = 0.5*widthpxls;
            popupheight = 0.1*heightpxls;
            radiogroupwidth = 0.9*widthpxls;
            radiogroupheight = 0.15*heightpxls;
            radiobuttonwidth =  100; %pxls
            radiobuttonheight=  20;% pxls
            fullheight = 1*heightpxls;
            
            
            
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
                            'units','pixels',...
                            'position', [left+xpadding,fullheight-ypadding-colorheight-top,colorwidth,colorheight],...
                            'String',value{i},...
                            'callback',{@cc_callback},...
                            'Tag',tag{i});
                        
                        left = left+xpadding+colorwidth;
                    end
                    obj.configcontrolpos = top+ypadding+colorheight;
                    
                case 'color'
                    %left = textwidth+xpadding/2;
                    for i = 1:numel(value)
                        obj.handles.configcontrols(end+1) = uicontrol('style','text',...
                            'Parent',obj.handles.panelleft,...
                            'units','pixels',...
                            'position',[left+xpadding,fullheight-ypadding-editheight-top,textwidth,editheight],...
                            'String',tag{i},...
                            'HorizontalAlignment','right');
                        left = left+xpadding+textwidth;
                        
                        obj.handles.configcontrols(end+1) = uicontrol('style','push',...
                            'Parent',obj.handles.panelleft,...
                            'units','pixels',...
                            'position', [left+xpadding/2,fullheight-ypadding-colorheight-top,colorwidth,colorheight],...
                            'String','',...
                            'callback',{@cc_selectcolor},...
                            'Tag',tag{i},...
                            'backgroundcolor',value{i});
                        
                        left = left+xpadding/2+colorwidth;
                    end
                    obj.configcontrolpos = top+ypadding+colorheight;
                    
                case 'checkbox'
                    for i = 1:numel(value)
                        left = textwidth+xpadding/2;
                        obj.handles.configcontrols(end+1) = uicontrol('style','checkbox',...
                            'Parent',obj.handles.panelleft,...
                            'units','pixels',...
                            'position',[left+xpadding,fullheight-ypadding-checkboxheight-top,checkboxwidth,checkboxheight],...
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
                            'units','pixels',...
                            'position',[left+xpadding,fullheight-ypadding-editheight-top,textwidth,editheight],...
                            'String',tag{i},...
                            'HorizontalAlignment','right');
                        
                        left = left+xpadding+textwidth;
                        
                        %editbox
                        obj.handles.configcontrols(end+1) = uicontrol('style','edit',...
                            'Parent',obj.handles.panelleft,...
                            'units','pixels',...
                            'position',[left+xpadding/2,fullheight-ypadding-editheight-top,editwidth,editheight],...
                            'String',num2str(value{i}),...
                            'Callback',@cc_callback,...
                            'Tag',tag{i});
                        
                        left = left+xpadding/2+editwidth;
                        
                    end
                    obj.configcontrolpos = top+ypadding+editheight;
                case 'vector'
                    for i = 1:numel(value)
                        %label
                        obj.handles.configcontrols(end+1) = uicontrol('style','text',...
                            'Parent',obj.handles.panelleft,...
                            'units','pixels',...
                            'position',[left+xpadding,fullheight-ypadding-editheight-top,textwidth,editheight],...
                            'String',tag{i},...
                            'HorizontalAlignment','right');
                        
                        left = left+xpadding+textwidth;
                        
                        %editbox
                        obj.handles.configcontrols(end+1) = uicontrol('style','edit',...
                            'Parent',obj.handles.panelleft,...
                            'units','pixels',...
                            'position',[left+xpadding/2,fullheight-ypadding-editheight-top,editwidth,editheight],...
                            'String',num2str(value{i}),...
                            'Callback',@cc_callback,...
                            'Tag',tag{i});
                        
                        left = left+xpadding/2+editwidth;
                        
                    end
                    obj.configcontrolpos = top+ypadding+editheight;
                    
                case 'list'
                    for i = 1:numel(value)
                        %label
                        obj.handles.configcontrols(end+1) = uicontrol('style','text',...
                            'Parent',obj.handles.panelleft,...
                            'units','pixels',...
                            'position',[left+xpadding,fullheight-ypadding-editheight-top,textwidth,editheight],...
                            'String',tag{i},...
                            'HorizontalAlignment','right');
                        
                        left = left+xpadding+textwidth;
                        
                        %popupmenu
                        obj.handles.configcontrols(end+1) = uicontrol('style','popupmenu',...
                            'Parent',obj.handles.panelleft,...
                            'units','pixels',...
                            'position',[left+xpadding/2,fullheight-ypadding-popupheight-top,popupwidth,popupheight],...
                            'String',other,...
                            'Value',find(contains(other,value{i})),...
                            'Tag',tag{i});
                        
                        left = left+xpadding/2+popupwidth;
                        
                    end
                    obj.configcontrolpos = top+ypadding+editheight;
                case 'radio'
                    obj.handles.configcontrols(end+1) = uibuttongroup('Parent',obj.handles.panelleft,...
                        'units','pixels',...
                        'position',[left+xpadding,fullheight-ypadding-checkboxheight-top,radiogroupwidth,radiogroupheight]);
                    
                    radiopanel = obj.handles.configcontrols(end);
                    set(radiopanel,'Clipping','off')
                    
                        left = 10;
                    for i = 1:numel(value)
                        
                        obj.handles.configcontrols(end+1) = uicontrol('style','radiobutton',...
                            'Parent',radiopanel,... 
                            'Position',[left,5,radiobuttonwidth,radiobuttonheight],...
                            'String',tag{i},...
                            'Tag',tag{i},...
                            'Value',value{i});
                        left = left+radiobuttonwidth;
                    end
                    
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
        
         function h = addon_addmenuitem(scene,addon,menuname,callback,parent)
             if nargin<5
                 parent = scene.handles.menu.addons.(addon).main;
             end
                
             if not(isfield(scene.handles.menu.addons.(addon),'external'))
                 scene.handles.menu.addons.(addon).external = [];
             end
             %deactivate install method
             scene.handles.menu.addons.(addon).main.Callback = '';

             %add menu
             if nargin>3
                 if not(iscell(callback))
                     callback = {callback};
                 end
                 callback{end+1} = scene; 
                scene.handles.menu.addons.(addon).external(end+1) =  uimenu(parent,'Text',menuname,'callback',callback);
             else
                 scene.handles.menu.addons.(addon).external(end+1) =  uimenu(parent,'Text',menuname);
             end
                 
              h = scene.handles.menu.addons.(addon).external(end);
            end
    end
    
    methods(Static)
        
        function thisScene = getscenedata(h)
            if isa(h,'ArenaScene')
                thisScene = h;
                return
            end
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
        
        function [actorlist,namelist,indexlist] =  getActorsOfClass(scene,classname)
            classes = ArenaScene.getClasses(scene.Actors);
            indexlist = find(ismember(classes,classname));
            actorlist = scene.Actors(indexlist);
            namelist = {actorlist.Tag};
            
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


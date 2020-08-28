classdef ArenaCropMenu < ArenaScene
    %ARENACROPMENU Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        boundingbox
        sliders
        flags
        cropped
        reference
    end
    
    methods
        
        function obj = CustomizeSceneToBeACropMenu(obj)
              
             xpadding = 0.02;
            ypadding = 0.02;
%              obj.handles.boundingboxpanel = uipanel('units','normalized',...
%                 'position',[xpadding 0.4 0.4 0.3],...
%                 'Title','Bounding box');
            
            obj.handles.axes.Position = [0.38 0 0.6 1];
            obj.handles.panelleft.Visible = 'off';
            obj.handles.panelright.Visible = 'off';
            obj.handles.btn_toggleright.Visible = 'off';
            obj.handles.btn_toggleleft.Visible = 'off';
            obj.handles.menu.atlas.main.Visible = 'off';
            obj.handles.menu.dynamic.main.Visible = 'off';
            obj.handles.menu.edit.main.Visible = 'off';
            obj.handles.menu.file.main.Visible = 'off';
            obj.handles.menu.transform.main.Visible = 'off';
            obj.handles.menu.view.main.Visible = 'off';
            obj.handles.btn_layeroptions.Visible = 'off';
            
            obj.handles.histogramaxes = axes('units','normalized',...
                'position',[0.05 0.78 0.35 0.20],...
                'fontsize',8,...
                'nextplot','add',...
                'box','off');
            
            obj.handles.bg = uibuttongroup(obj.handles.figure,'units','normalized','Position',[0.05 0.64 0.2 0.1]);
            obj.handles.light = uicontrol(obj.handles.bg,'Style','radiobutton','Position',[10 60 91 15],'String','light','callback',@darklightcallback);
            obj.handles.surface = uicontrol(obj.handles.bg,'Style','radiobutton','Position',[10 38 91 15],'String','surface','Value',1,'callback',@darklightcallback);
            obj.handles.dark = uicontrol(obj.handles.bg,'Style','radiobutton','Position',[10 16 91 15],'String','dark','callback',@darklightcallback);
            obj.handles.bg.BackgroundColor = [0 0 0];
            obj.handles.bg.BorderWidth = 0;
            obj.handles.figure.Color = [0 0 0];
            obj.handles.light.BackgroundColor = [0 0 0];
            obj.handles.dark.BackgroundColor = [0 0 0];
            obj.handles.surface.BackgroundColor = [0 0 0];
            obj.handles.light.ForegroundColor = [1 1 1];
            obj.handles.dark.ForegroundColor = [1 1 1];
            obj.handles.surface.ForegroundColor = [1 1 1];
            
            
            %obj.handles.figure.WindowButtonUpFcn = @clicked;
            
            
                        %sliders
                        
                        obj.sliders.xmin = uicontrol(obj.handles.figure,'Style','slider',...
                            'units','pixels',...
                            'Position',[50,100,500,20],...
                            'callback',@updatemesh);
                        obj.sliders.xmax = uicontrol(obj.handles.figure,'Style','slider',...
                            'units','pixels',...
                            'Position',[50,120,500,20],...
                            'callback',@updatemesh);
                        
                        obj.sliders.ymin = uicontrol(obj.handles.figure,'Style','slider',...
                            'units','pixels',...
                            'Position',[50,150,500,20],...
                            'callback',@updatemesh);
                        
                        obj.sliders.ymax = uicontrol(obj.handles.figure,'Style','slider',...
                            'units','pixels',...
                            'Position',[50,170,500,20],...
                            'callback',@updatemesh);
                        
                        obj.sliders.zmin = uicontrol(obj.handles.figure,'Style','slider',...
                            'units','pixels',...
                            'Position',[50,200,500,20],...
                            'callback',@updatemesh);
                        
                        obj.sliders.zmax = uicontrol(obj.handles.figure,'Style','slider',...
                            'units','pixels',...
                            'Position',[50,220,500,20],...
                            'callback',@updatemesh);
                        
                        addlistener(obj.sliders.xmin,'Value','PreSet',@myCallbackFunc);
                        addlistener(obj.sliders.xmax,'Value','PreSet',@myCallbackFunc);
                        addlistener(obj.sliders.ymin,'Value','PreSet',@myCallbackFunc);
                        addlistener(obj.sliders.ymax,'Value','PreSet',@myCallbackFunc);
                        addlistener(obj.sliders.zmin,'Value','PreSet',@myCallbackFunc);
                        addlistener(obj.sliders.zmax,'Value','PreSet',@myCallbackFunc);
                        
                        obj.handles.savebutton = uicontrol(obj.handles.figure,'Style','pushbutton',...
                            'units','normalized',...
                            'Position',[0.87,0.05,0.08,0.05],...
                            'String','Save and close',...
                            'callback',@btnsaveclose);
                        
                        
                        %uistack(obj.handles.bg,'bottom');
            
            function darklightcallback(varargin)
                myCallbackFunc(varargin)
                updatemesh(varargin)
            end
            
            function myCallbackFunc(varargin)
                if not(obj.flags.loading)
                    ld = Vector3D([get(obj.sliders.xmin,'Value'),...
                        get(obj.sliders.ymin,'Value'),...
                        get(obj.sliders.zmin,'Value')]);
                    
                    ru = Vector3D([get(obj.sliders.xmax,'Value'),...
                        get(obj.sliders.ymax,'Value'),...
                        get(obj.sliders.zmax,'Value')]);
               
                   obj = updateBoundingBox(obj,ld,ru);
                end
            end
         function updatemesh(varargin)
            
                
                 
                   %update mesh
                obj.Actors(2).Data.Source = obj.cropped;
                delete(obj.Actors(2).Visualisation.handle)

                currentsettings = obj.Actors(2).Visualisation.settings;
                currentsettings.complexity = 100;
                visualize(obj.Actors(2),currentsettings,obj.Actors(2).Data,obj);

         end
        
         function btnsaveclose(varargin)
            obj = varargin{1}.Parent.UserData;
            
            obj.reference.Data.Source.Voxels = obj.cropped.Voxels;
            obj.reference.Data.Source.R = obj.cropped.R;
            obj.reference.Data.Source.LeftDown = obj.cropped.LeftDown;
            obj.reference.Data.Source.RightUp = obj.cropped.RightUp;
            
            obj.reference.Data.Source.imwarp(obj.reference.Data.Source.T)
            
            currentsettings = obj.reference.Visualisation.settings;
            if currentsettings.threshold==obj.Actors(2).Visualisation.settings.threshold
                currentsettings.threshold = currentsettings.threshold+0.001; %triggers remeshing
            else
                currentsettings.threshold = obj.Actors(2).Visualisation.settings.threshold;
                
            end
            delete(obj.reference.Visualisation.handle)
                visualize(obj.reference,currentsettings,obj.reference.Data,obj.reference.Scene);
                
                delete(obj.handles.figure)
            
            
        end
             
        end
        
       
        
        function obj = MakeACube(obj)
            %bounding box
                ld = Vector3D([-1 -1 -1]);
                ru = Vector3D([1 1 1]);
                axes(obj.handles.axes)
                obj.boundingbox = plot3([ld.x,ru.x,ru.x,ld.x,ld.x,ld.x,ru.x,ru.x,ld.x,ld.x,ru.x,ru.x,ru.x,ld.x,ld.x,ru.x,ru.x],...
          [ld.y,ld.y,ru.y,ru.y,ld.y,ld.y,ld.y,ru.y,ru.y,ld.y,ld.y,ld.y,ru.y,ru.y,ru.y,ru.y,ru.y],...
          [ld.z,ld.z,ld.z,ld.z,ld.z,ru.z,ru.z,ru.z,ru.z,ru.z,ru.z,ld.z,ld.z,ld.z,ru.z,ru.z,ld.z]);
        end
        
        function obj = ArenaCropMenu()
            obj.flags.loading = 0; %triggered by the load function
            obj.flags.startup = 1;
            obj.flags.remesh = 0;
            
            obj = create(obj,'CROP MENU');
            obj = CustomizeSceneToBeACropMenu(obj);
            obj = MakeACube(obj);
            
            obj.flags.startup = 0;
             


        end
        
        
        
        function obj = load(obj, newActor)
            obj.flags.loading = 1;
            obj.reference = newActor;
            switch class(newActor.Data.Source)
                case 'CroppedVoxelData'
                    slice = newActor.Data.Source.parent.getslice.see(obj);
                     
                     parent_ld = Vector3D([newActor.Data.Source.parent.R.XWorldLimits(1),...
                        newActor.Data.Source.parent.R.YWorldLimits(1),...
                        newActor.Data.Source.parent.R.ZWorldLimits(1)]);
                    
                     parent_ru = Vector3D([newActor.Data.Source.parent.R.XWorldLimits(2),...
                        newActor.Data.Source.parent.R.YWorldLimits(2),...
                        newActor.Data.Source.parent.R.ZWorldLimits(2)]);
                    crop_ld = Vector3D(min([newActor.Data.Source.LeftDown.x,newActor.Data.Source.RightUp.x]),...
                        min([newActor.Data.Source.LeftDown.y,newActor.Data.Source.RightUp.y]),...
                        min([newActor.Data.Source.LeftDown.z,newActor.Data.Source.RightUp.z]));
                        
                    crop_ru = Vector3D(max([newActor.Data.Source.LeftDown.x,newActor.Data.Source.RightUp.x]),...
                        max([newActor.Data.Source.LeftDown.y,newActor.Data.Source.RightUp.y]),...
                        max([newActor.Data.Source.LeftDown.z,newActor.Data.Source.RightUp.z]));
                    
                    cropped = newActor.Data.Source.parent.crop(newActor.Data.Source.LeftDown,newActor.Data.Source.RightUp);
                    cropped.smooth;
                    cropactor = cropped.getmesh(newActor.Data.Settings.T).see(obj);
                    
                    
                otherwise
                    
                    cropped = newActor.Data.Source.convertToCropped();
                    obj.reference.Data.Source = cropped;
                    cropped.smooth;
                    slice = cropped.parent.getslice.see(obj);
                    
                    cropactor = cropped.getmesh(newActor.Data.Settings.T).see(obj);
                    
                     parent_ld = Vector3D([newActor.Data.Source.R.XWorldLimits(1),...
                        newActor.Data.Source.R.YWorldLimits(1),...
                        newActor.Data.Source.R.ZWorldLimits(1)]);
                    
                     parent_ru = Vector3D([newActor.Data.Source.R.XWorldLimits(2),...
                        newActor.Data.Source.R.YWorldLimits(2),...
                        newActor.Data.Source.R.ZWorldLimits(2)]);
                    crop_ld  = parent_ld;
                    crop_ru = parent_ru;

            end
               
                    
                    
                    
                    
                    updateBoundingBox(obj,crop_ld,crop_ru)
            
            %setsliders
            set(obj.sliders.xmin,'Min',[parent_ld.x],'Max',[parent_ru.x]);
            set(obj.sliders.xmax,'Min',[parent_ld.x],'Max',[parent_ru.x]);
            set(obj.sliders.ymin,'Min',[parent_ld.y],'Max',[parent_ru.y]);
            set(obj.sliders.ymax,'Min',[parent_ld.y],'Max',[parent_ru.y]);
            set(obj.sliders.zmin,'Min',[parent_ld.z],'Max',[parent_ru.z]);
            set(obj.sliders.zmax,'Min',[parent_ld.z],'Max',[parent_ru.z]);
            
            set(obj.sliders.xmin,'Value',crop_ld.x);
            set(obj.sliders.xmax,'Value',crop_ru.x);
            set(obj.sliders.ymin,'Value',crop_ld.y);
            set(obj.sliders.ymax,'Value',crop_ru.y);
            set(obj.sliders.zmin,'Value',crop_ld.z);
            set(obj.sliders.zmax,'Value',crop_ru.z);
            
%             addlistener(obj.sliders.xmin,'Value','PreSet',@(~,~)disp('hi'));

           
            
            
            cropactor.Visualisation.settings.colorFace= newActor.Visualisation.settings.colorFace;
            cropactor.Visualisation.settings.colorEdge = newActor.Visualisation.settings.colorEdge;
            cropactor.Visualisation.handle.FaceColor = newActor.Visualisation.settings.colorFace;
            cropactor.Visualisation.handle.EdgeColor = newActor.Visualisation.settings.colorEdge;
            
            
            
            axes(obj.handles.histogramaxes)
            obj.handles.histogram = histogram(cropactor.Data.Source.Voxels(:),50);
            obj.handles.histogram.HitTest = 'off';
            obj.handles.histogram.FaceColor = obj.Actors(2).Visualisation.settings.colorFace;
            obj.handles.histogramaxes.XColor = 'w';
            obj.handles.histogramaxes.YColor = 'w';
            obj.handles.histogramaxes.Color = 'none';
            set(obj.handles.histogramaxes,'ButtondownFcn',@chooseThreshold);
            set(gca, 'YScale', 'log')
            xlabel('voxel value')
            ylabel('occurrence')
                    hold on
                obj.handles.histogramline = line([newActor.Data.Settings.T newActor.Data.Settings.T],obj.handles.histogramaxes.YLim);
                obj.handles.histogramline.LineWidth = 3;
                obj.handles.histogramline.Color = [1 1 1];
                
                
            %disableDefaultInteractivity(obj.handles.histogramaxes)
            axes(obj.handles.axes)
            
            obj.flags.loading =0 ;
            
            
            function chooseThreshold(varargin)
                hit = varargin{2};
                location = hit.IntersectionPoint(1);
                varargin{2}.Source.Parent.UserData.Actors(2).Visualisation.settings.threshold = location;
                
                currentsettings = varargin{2}.Source.Parent.UserData.Actors(2).Visualisation.settings;
                delete(varargin{2}.Source.Parent.UserData.Actors(2).Visualisation.handle)
                visualize(varargin{2}.Source.Parent.UserData.Actors(2),currentsettings,varargin{2}.Source.Parent.UserData.Actors(2).Data,varargin{2}.Source.Parent.UserData);
                
                axes(obj.handles.histogramaxes)
                obj.handles.histogramline.XData = [location location];
                axes(obj.handles.axes)
              
            end
                
            
        end
       
        
        
        function obj= updateBoundingBox(obj,ld,ru)
     
            
            
                obj.boundingbox.XData = [ld.x,ru.x,ru.x,ld.x,ld.x,ld.x,ru.x,ru.x,ld.x,ld.x,ru.x,ru.x,ru.x,ld.x,ld.x,ru.x,ru.x];
               obj.boundingbox.YData = [ld.y,ld.y,ru.y,ru.y,ld.y,ld.y,ld.y,ru.y,ru.y,ld.y,ld.y,ld.y,ru.y,ru.y,ru.y,ru.y,ru.y];
               obj.boundingbox.ZData = [ld.z,ld.z,ld.z,ld.z,ld.z,ru.z,ru.z,ru.z,ru.z,ru.z,ru.z,ld.z,ld.z,ld.z,ru.z,ru.z,ld.z];
        
               if not(obj.flags.startup)
                cropped = obj.Actors(1).Data.parent.crop(ld,ru);
                cropped.smooth;
                
                if not(obj.flags.loading)
                    cropped = cropped.padcropped(obj.handles.bg.SelectedObject.String);
                end
                
                obj.cropped = cropped;
               

                %update histogram
                [~,BinEdges] = histcounts(cropped.Voxels(:),50);
                BinLimits = [min(BinEdges),max(BinEdges)];
                obj.handles.histogram.Data= cropped.Voxels(:);
                obj.handles.histogram.BinEdges= BinEdges;
                obj.handles.histogram.BinLimits= BinLimits;
                
                obj.flags.remesh = 10;
                center = mean([ld.getArray,ru.getArray]');
                
                %move camera
                current_target = camtarget;
                max_camera_step = 1;
                step = Vector3D(center - current_target);
                step.norm
                if step.norm > max_camera_step
                    focus = Vector3D(current_target) + step.unit*max_camera_step;
                else
                    focus = Vector3D(center);
                end
                    
                
                
                camtarget(focus.getArray)
                
                
            end
            
            function cropped = padcropped(cropped)
                if obj.flags.loading;return;end
                switch obj.handles.bg.SelectedObject.String
                    case 'surface'
                        %nothing.
                    case 'light'
                        cropped.R.XWorldLimits = [cropped.R.XWorldLimits] + [-1 1]*cropped.R.PixelExtentInWorldX;
                        cropped.R.ImageSize = cropped.R.ImageSize + [2 2 2]; 
                        
                        v =cropped.Voxels;
                        cropped.Voxels = ones(size(v)+[2 2 2])*(min(v(:))-1);
                        cropped.Voxels(2:end-1,2:end-1,2:end-1) =  v;
                        
                    case 'dark'
                        cropped.R.XWorldLimits = [cropped.R.XWorldLimits] + [-1 1]*cropped.R.PixelExtentInWorldX;
                        cropped.R.ImageSize = cropped.R.ImageSize + [2 2 2]; 
                        
                        v =cropped.Voxels;
                        cropped.Voxels = ones(size(v)+[2 2 2])*(max(v(:))+1);
                        cropped.Voxels(2:end-1,2:end-1,2:end-1) =  v;
                end
                
                
                
            end
        end
        
        
       
        
            
    end
end


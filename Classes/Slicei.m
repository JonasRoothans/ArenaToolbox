classdef Slicei < handle
    %SLICEI Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        handle
        vol
        I2X
        slicedim
        sliceidx
        cmap
        light
        dark
        opacity
        clipDark
    end
    
    properties (Access = private)
        startray
        startidx
    end

    
    methods
        function obj = Slicei()
            
        end
        
        function obj = getFromVoxelData(obj,vd)
              T = [diag([vd.R.PixelExtentInWorldX,vd.R.PixelExtentInWorldY,vd.R.PixelExtentInWorldZ]),[vd.R.XWorldLimits(1);vd.R.YWorldLimits(1);vd.R.ZWorldLimits(1)]];
              obj.vol = permute(vd.Voxels,[2 1 3]);
              obj.I2X = T;
              obj.slicedim = 3;
              obj.sliceidx = round(size(obj.vol,3)/2);
              obj.cmap = A_colorgradient([0 0 0],[1 1 1],255);
              obj.light = max(obj.vol(:));
              obj.dark = min(obj.vol(:));
              obj.opacity = 1;
              obj.clipDark = 0;
              
        end
        
        function [thisActor,thisScene] = see(obj,sceneobj)
            global arena
            if nargin==1
                if isempty(arena)
                    evalin('base','startArena');
                    thisScene = arena.sceneselect(1);
                else
                    thisScene = arena.sceneselect();
                end
            else
                thisScene = sceneobj;
            end
            
            if isempty(thisScene);return;end %user cancels
           
            obj.update_slice(thisScene);
            thisActor = thisScene.newActor(obj);
        end
        
        function update_slice(obj,scene)
            if ndims(obj.vol) == 3         %Scalar mode
            elseif ndims(obj.vol) == 4     %RGB mode
            else
                error('Only scalar and RGB images supported')
            end
            
                        % Create the slice
            if obj.slicedim == 3 % k
                ij2xyz = obj.I2X(:,[1 2]);
                ij2xyz(:,3) = obj.I2X*[0 0 obj.sliceidx 1]';
                if round(obj.sliceidx)<1
                    obj.sliceidx=1;
                elseif round(obj.sliceidx)>size(obj.vol,3)
                    obj.sliceidx=size(obj.vol,3);
                end
                sliceim = squeeze(obj.vol(:,:,round(obj.sliceidx),:));
            elseif obj.slicedim == 2 % j
              ij2xyz = obj.I2X(:,[1 3]);
              ij2xyz(:,3) = obj.I2X*[0 obj.sliceidx 0 1]';
              if round(obj.sliceidx)<1
                  obj.sliceidx=1;
              elseif round(obj.sliceidx)>size(obj.vol,2)
                  obj.sliceidx=size(obj.vol,2);
              end
              sliceim = squeeze(obj.vol(:,round(obj.sliceidx),:,:));
            elseif obj.slicedim == 1 % i
              ij2xyz = obj.I2X(:,[2 3]);
              ij2xyz(:,3) = obj.I2X*[obj.sliceidx 0 0 1]';
              if round(obj.sliceidx)<1
                  obj.sliceidx=1;
              elseif round(obj.sliceidx)>size(obj.vol,1)
                  obj.sliceidx=size(obj.vol,1);
              end
              sliceim = squeeze(obj.vol(round(obj.sliceidx),:,:,:));
            else
                error('Slicedim should be 1, 2 or 3')
            end
            
            grayscale_sliceim = sliceim;
            %set color
            RGBvector = A_vals2colormap(sliceim(:),obj.cmap,[obj.dark,obj.light]);
            sliceim = reshape(RGBvector,[size(sliceim),3]);
             
            
            %set axes
            axes(scene.handles.axes)
            if isempty(obj.handle)
                obj.handle = image3(sliceim,ij2xyz);
            else
                obj.handle = image3(sliceim,ij2xyz,obj.handle);
            end
            
            %set transparency
            obj.handle.FaceAlpha = obj.opacity;
            obj.handle.FaceColor = 'texturemap';
            
            %function disabled
             if obj.clipDark
                obj.handle.FaceColor = obj.cmap(end,:);
                obj.handle.FaceAlpha = 'flat';
                obj.handle.AlphaDataMapping = 'none';
                obj.handle.AlphaData = double(grayscale_sliceim > obj.dark) * obj.opacity;
            end
            
            
            if isa(scene,'ArenaScene')
                scene = figure(scene.handles.figure);
            end
            set(obj.handle,'ButtonDownFcn',{@obj.startmovit,scene})
        end
            
        function startmovit(obj,hObject,eventdata,scene)
            obj.startray = get(gca,'CurrentPoint');
            obj.startidx = obj.sliceidx;
            
            set(scene,'WindowButtonMotionFcn',@obj.movit)
            set(scene,'WindowButtonUpFcn',@obj.stopmovit);
        end
        
        function movit(obj,hObject,eventdata)
            scene = hObject.UserData;
  
            try
                if isequal(obj.startray,[])
                    return
                end
            end
            
            nowray = get(gca,'CurrentPoint');
            
            % Project rays on slice-axis
            s = obj.I2X(1:3,obj.slicedim);
            a = obj.startray(1,:)';
            b = obj.startray(2,:)';
            alphabeta = pinv([s'*s, -s'*(b-a);(b-a)'*s, -(b-a)'*(b-a)])*[s'*a, (b-a)'*a]';
            pstart = alphabeta(1)*s;
            alphastart = alphabeta(1);
            a = nowray(1,:)';
            b = nowray(2,:)';
            alphabeta = pinv([s'*s, -s'*(b-a);(b-a)'*s, -(b-a)'*(b-a)])*[s'*a, (b-a)'*a]';
            pnow = alphabeta(1)*s;
            alphanow = alphabeta(1);
            slicediff = alphanow-alphastart;
            
            obj.sliceidx = obj.startidx+slicediff;
            obj.sliceidx = min(max(1,obj.sliceidx),size(obj.vol,obj.slicedim));
            obj.update_slice(scene)%gui.vol, gui.I2X, gui.slicedim, gui.sliceidx, gui.handle, controlhandles, resultfig);
            drawnow;
            
            % Store gui object
            %set(get(gcf,'UserData'),'UserData',gui);
            

            
            
        end
        
        function stopmovit(obj,scene, eventdata)
            set(scene,'WindowButtonUpFcn','');
            set(scene,'WindowButtonMotionFcn','');
            obj.startray = [];
            
            %disabled this, and still seems to work?
            
            %find corresponding actor
            for iActor  = scene.UserData.Actors
                if iActor.Data == obj
                    
                    vector = [0 0 0];
                    vector(obj.slicedim) = obj.sliceidx;
                    T = obj.I2X;
                    T(4,4) = 1;
                    worldspace = SDK_transform3d(vector,T');

                    iActor.Visualisation.settings.slice = worldspace(obj.slicedim);
                    iActor.updateCC(scene.UserData);
                    break
                end
            end
%             drawnow;
            
        
            
        end
        
        function cog = getCOG(obj)
             vector = size(obj.vol)/2;
             vector(obj.slicedim) = obj.sliceidx;
             T = obj.I2X;
                    T(4,4) = 1;
                    cog = Vector3D(SDK_transform3d(vector,T'));
                   

        end
            
    end
end


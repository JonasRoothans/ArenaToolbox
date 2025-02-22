function [] = A_mouse_camera(hfig)
% Execute this function to a Figure hfig in order to set camera movements
% to the mouse.
%
% Left click: rotate
% Wheel click / Left click + shift: move
% Right click / Left click + ctrl: zoom


figLastPoint = []; % global variable to store previous cursor position
zoomFactor = 10;
panFactor = 2;
orbitFactor = 7;
zoomFactor_jr = 0.1;

set(hfig, 'WindowButtonDownFcn', @down_fcn);
set(hfig, 'WindowButtonUpFcn', @up_fcn);
set(hfig, 'WindowScrollWheelFcn', @zoom_fcn);

try
    %what is this?
    %well, this function is also called when right mouse click is done
    %while in the slice sliding mode. This line redirects to the panning
    %functionality
    if strcmp(hfig.UserData.handles.cameratoolbar.slide3dtog.UserData,'on')
        down_fcn(hfig) %simulate right mouse click
    end
catch
end


    function [] = zoom_fcn(hfig, evt)
        
       
        
        %check if mouse is hovering the listbox
        if strcmp(hfig.UserData.handles.panelright.Visible,'on')
            listboxpos = hfig.UserData.handles.panelright.Position;
            currpt = get(hfig,'CurrentPoint');
            Xinside = currpt(1)>listboxpos(1) && currpt(1) < listboxpos(1)+listboxpos(3);
            Yinside = currpt(2)>listboxpos(2) && currpt(2) < listboxpos(2)+listboxpos(4);
            if Xinside && Yinside
                %don't zoom
                return
            end
        end

        
        currentPos = Vector3D(campos);
        currentTarget = Vector3D(camtarget);
        difference = currentPos-currentTarget;
        distance = difference.norm;
        direction = difference.unit;
        
        if evt.VerticalScrollCount > 0
            newpos = currentPos+direction*distance*zoomFactor_jr;
            campos([newpos.x,newpos.y,newpos.z])
            % camzoom(1 + evt.VerticalScrollCount / zoomFactor)
        else
            %camzoom(1 / (1 + abs(evt.VerticalScrollCount) / zoomFactor))
            newpos = currentPos-direction*distance*zoomFactor_jr;
            campos([newpos.x,newpos.y,newpos.z])
        end
     
        
    end


    function [] = down_fcn(hfig, evt)
      
        
            clickType = get(hfig,'selectionType');
     
        set(hfig, 'WindowButtonMotionFcn',{@motion_callback,clickType});
        
        % set cursor type
        switch clickType
            case 'normal'
                setptr(gcf, 'rotate');
            case 'alt'
                setptr(gcf, 'hand');
            case 'extend'
                selectlayer(hfig)
            case 'open'
                disp('yes')
                
                 switch hfig.UserData.handles.btn_toggleleft.Value
                    case 1
                        set(hfig.UserData.handles.panelleft,'Visible','off')
                        set(hfig.UserData.handles.panelright,'Visible','off')
                        set(hfig.UserData.handles.btn_toggleleft,'String','open panel')
                        set(hfig.UserData.handles.btn_toggleright,'String','open panel')
                        set(hfig.UserData.handles.btn_toggleleft, 'Value',0)
                        set(hfig.UserData.handles.btn_toggleright, 'Value',0)
                    case 0
                         set(hfig.UserData.handles.panelleft,'Visible','on')
                        set(hfig.UserData.handles.panelright,'Visible','on')
                        set(hfig.UserData.handles.btn_toggleleft,'String','close panel')
                        set(hfig.UserData.handles.btn_toggleright,'String','close panel')
                        set(hfig.UserData.handles.btn_toggleleft, 'Value',1)
                        set(hfig.UserData.handles.btn_toggleright, 'Value',1)
                end
                hfig.UserData.handles.btn_layeroptions.Visible = hfig.UserData.handles.panelright.Visible;
                
                
        end
    end

    function set_defaultview
        % get stored default view preferences and call ea_defaultview
        prefs = ea_prefs;
        v = prefs.machine.view;
        togglestates = prefs.machine.togglestates;
        ea_defaultview_transition(v,togglestates);
        ea_defaultview(v,togglestates);
    end


    function [] = motion_callback(hfig, evt, clickType)
        % from matlab's CameraToolBarManager.m
        
        currpt = get(hfig,'CurrentPoint');
        try
            pt = matlab.graphics.interaction.internal.getPointInPixels(hfig,currpt(1:2));
        catch % old matlab version
            pt = currpt;
        end
        if isempty(figLastPoint)
            figLastPoint = pt;
        end
        deltaPix  = pt-figLastPoint;
        figLastPoint = pt;
        
        switch clickType
            case 'normal' %this was 'normal'
                orbitPangca(deltaPix/orbitFactor, 'o');
            case 'alt'
                dollygca(deltaPix/panFactor);

        end
        
    end

    function selectlayer(hfig)
        
        ax = hfig.UserData.handles.axes;
        hObj = hittest(hfig);
        
        for i = 1:numel(hfig.UserData.Actors)
            hit = 0;
            if isa(hfig.UserData.Actors(i).Data,'Electrode')
                for iH = 1:numel(hfig.UserData.Actors(i).Visualisation.handle)
                    if hfig.UserData.Actors(i).Visualisation.handle(iH) == hObj
                        hit = 1;
                        break
                    end
                end
                
            elseif hfig.UserData.Actors(i).Visualisation.handle == hObj
                hit = 1;
            end
            
            if hit
                hfig.UserData.handles.panelright.Value=i;
                hfig.UserData.Actors(i).updateCC(hfig.UserData)
                disp(hfig.UserData.Actors(i).Tag)
                hfig.UserData.updateMenu()
            end
                
        end
        
    end

    function dollygca(xy)
        % from matlab's CameraToolBarManager.m
        haxes = gca;
        camdolly(haxes,-xy(1), -xy(2), 0, 'movetarget', 'pixels')
        drawnow
    end

    function orbitPangca(xy, mode)
        % from matlab's CameraToolBarManager.m
        %mode = 'o';  orbit
        %mode = 'p';  pan
        
        %coordsystem = lower(hObj.coordsys);
        coordsystem = 'z';
        
        haxes = gca;
        
        if coordsystem(1)=='n'
            coordsysval = 0;
        else
            coordsysval = coordsystem(1) - 'x' + 1;
        end
        
        xy = -xy;
        
        if mode=='p' % pan
            panxy = xy*camva(haxes)/500;
        end
        
        if coordsysval>0
            d = [0 0 0];
            d(coordsysval) = 1;
            
            up = camup(haxes);
            upsidedown = (up(coordsysval) < 0);
            if upsidedown
                xy(1) = -xy(1);
                d = -d;
            end
            
            % Check if the camera up vector is parallel with the view direction;
            % if not, set the up vector
            try
                check = any(matlab.graphics.internal.CameraToolBarManager.crossSimple(d,campos(haxes)-camtarget(haxes)));
            catch % Matlab 2017
                check = any(crossSimple(d,campos(haxes)-camtarget(haxes)));
            end
            if check
                camup(haxes,d)
            end
        end
        
        flag = 1;
        
        %while sum(abs(xy))> 0 && (flag || hObj.moving) && ishghandle(haxes)
        while sum(abs(xy))> 0 && (flag) && ishghandle(haxes)
            flag = 0;
            if ishghandle(haxes)
                if mode=='o' %orbit
                    if coordsysval==0 %unconstrained
                        camorbit(haxes,xy(1), xy(2), coordsystem)
                    else
                        camorbit(haxes,xy(1), xy(2), 'data', coordsystem)
                    end
                else %pan
                    if coordsysval==0 %unconstrained
                        campan(haxes,panxy(1), panxy(2), coordsystem)
                    else
                        campan(haxes,panxy(1), panxy(2), 'data', coordsystem)
                    end
                end
                %updateScenelightPosition(hObj,haxes);
                %localDrawnow(hObj);
                drawnow
            end
        end
    end

    function zoomgca(xy)
        % from matlab's CameraToolBarManager.m
        
        haxes = gca;
        
        q = max(-.9, min(.9, sum(xy)/70));
        q = 1+q;
        
        % heuristic avoids small view angles which will crash on Solaris
        MIN_VIEW_ANGLE = .001;
        MAX_VIEW_ANGLE = 75;
        vaOld = camva(gca);
        camzoom(haxes,q);
        va = camva(haxes);
        %If the act of zooming puts us at an extreme, back the zoom out
        if ~((q>1 || va<MAX_VIEW_ANGLE) && (va>MIN_VIEW_ANGLE))
            set(haxes,'CameraViewAngle',vaOld);
        end
        
        drawnow
    end

    function [] = up_fcn(hfig, evt)
        % reset motion and cursor
        set(hfig,'WindowButtonMotionFcn',[]);
        
        if strcmp(hfig.UserData.handles.cameratoolbar.slide3dtog.UserData,'on')
            set(hfig,'WindowButtonDownFcn', []);
        end
        
        figLastPoint = [];
        setptr(gcf, 'arrow');
    end

    function c=crossSimple(a,b)
        c(1) = b(3)*a(2) - b(2)*a(3);
        c(2) = b(1)*a(3) - b(3)*a(1);
        c(3) = b(2)*a(1) - b(1)*a(2);
    end

end

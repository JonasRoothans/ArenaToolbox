function [h_toolbar] = A_cameratoolbar(figurehandle)
%A_CAMERATOOLBAR Summary of this function goes here
%   Detailed explanation goes here

h_toolbar.main =uitoolbar(figurehandle);


% add custom rotator:
h_toolbar.rotate3dtog=uitoggletool(h_toolbar.main, 'CData', A_loadicon('camera'),...
    'TooltipString', 'Rotate 3D', 'OnCallback', {@A_toolbar_rotate,'on'},...
    'OffCallback', {@A_toolbar_rotate,'off'}, 'State', 'on');
h_toolbar.slide3dtog=uitoggletool(h_toolbar.main, 'CData', A_loadicon('move','gray'),...
    'TooltipString', 'Slide Slices', 'OnCallback', {@A_toolbar_slideslices,'on'},...
    'OffCallback', {@A_toolbar_slideslices,'off'}, 'State', 'off');
% h_toolbar.magnifyplus=uitoggletool(h_toolbar.main,'CData',A_loadicon('zoomin'),...
%     'TooltipString', 'Zoom In', 'OnCallback', {@A_toolbar_zoomin,'on'},...
%     'OffCallback', {@A_toolbar_zoomin,'off'}, 'State', 'off');
% h_toolbar.magnifyminus=uitoggletool(h_toolbar.main, 'CData', A_loadicon('zoomout'),...
%     'TooltipString', 'Zoom Out', 'OnCallback', {@A_toolbar_zoomout,'on'},...
%     'OffCallback', {@A_toolbar_zoomout,'off'}, 'State', 'off');
% h_toolbar.handtog=uitoggletool(h_toolbar.main, 'CData', A_loadicon('pan'),...
%     'TooltipString', 'Pan Scene', 'OnCallback', {@A_toolbar_pan,'on'},...
%     'OffCallback', {@A_toolbar_pan,'off'}, 'State', 'off');

h_toolbar.screenshot=uitoggletool(h_toolbar.main, 'CData', A_loadicon('screenshot'),...
    'TooltipString', 'Screenshot', 'OnCallback', {@A_toolbar_screenshot,'on'},...
    'OffCallback', {@A_toolbar_screenshot,'off'}, 'State', 'off','Separator','on');



camva(figurehandle.CurrentAxes,'manual')
figurehandle.CurrentAxes.Projection = 'perspective';
figurehandle.CurrentAxes.CameraViewAngleMode = 'manual';
figurehandle.CurrentAxes.PlotBoxAspectRatioMode = 'manual';

A_mouse_camera(figurehandle);

end


function A_toolbar_rotate(hObject,~,cmd)
scene = ArenaScene.getscenedata(hObject);
toolbar = scene.handles.cameratoolbar;
figure = scene.handles.figure;

toolbar.rotate3dtog.UserData = 'on';
toolbar.rotate3dtog.CData = A_loadicon('camera');
toolbar.slide3dtog.UserData = 'off';
toolbar.slide3dtog.CData = A_loadicon('move','gray');

%get axes
ax = scene.handles.axes;
% 
% if strcmp(cmd,'off')
%     set(figure,'Pointer','arrow')
%     return
% end

set(figure,'Pointer','circle')


% disable click actions on surfaces (image slices)
set(findobj(ax.Children,'Type','surface'),'HitTest','off');

A_mouse_camera(figure);

end

function A_toolbar_slideslices(hObject,~,cmd)

scene = ArenaScene.getscenedata(hObject);
toolbar = scene.handles.cameratoolbar;
figure = scene.handles.figure;
% 
 toolbar.rotate3dtog.UserData = 'off';
 toolbar.rotate3dtog.CData = A_loadicon('camera','gray');
 toolbar.slide3dtog.UserData = 'on';
 toolbar.slide3dtog.CData = A_loadicon('move');

% if strcmp(cmd,'off')
%     return
% end
% reset button down function
set(figure,'WindowButtonDownFcn', []);

%get axes
ax = scene.handles.axes;
set(findobj(ax.Children,'Type','surface'),'HitTest','on'); 
end

function A_toolbar_screenshot(hObject,~,cmd)
scene = ArenaScene.getscenedata(hObject);
toolbar = scene.handles.cameratoolbar;
figure = scene.handles.figure;
figure.InvertHardcopy = 'off';

[fn,pn] = uiputfile([scene.Title,strrep(datestr(datetime),':','-'),'.png']);

scene.handles.panelleft.Visible = 'off';
scene.handles.panelright.Visible = 'off';
scene.handles.btn_toggleleft.Visible = 'off';
scene.handles.btn_toggleright.Visible = 'off';
scene.handles.btn_layeroptions.Visible = 'off';


print(figure,fullfile(pn,fn),'-dpng','-r300');

scene.handles.panelleft.Visible = 'on';
scene.handles.panelright.Visible = 'on';
scene.handles.btn_toggleleft.Visible = 'on';
scene.handles.btn_toggleright.Visible = 'on';
scene.handles.btn_layeroptions.Visible = 'on';

end

function A_toolbar_zoomin(varargin)
disp('zoom in!')
%steal from ea_zoomin (ea_imageclassifier)
end

function A_toolbar_zoomout(varargin)
disp('zoom out!')
%steal from ea_zoomout
end

function A_toolbar_pan(varargin)
disp('pan!')
%steal from ea_pan
end

function icon = A_loadicon(type,mode)
switch type
    case 'camera'
        icon = imread('camera.jpg');
    case 'move'
         icon = imread('plane.jpg');
    case 'zoomin'
         icon = imread('zoom.jpg');
    case 'zoomout'
         icon = imread('zoom.jpg');
    case 'pan'
         icon = imread('pan.jpg');
    case 'screenshot'
        icon = imread('screenshot.jpg');
end
if nargin==2
switch mode
    case 'gray'
        icon = repmat(rgb2gray(icon),1,1,3);
end
end
end



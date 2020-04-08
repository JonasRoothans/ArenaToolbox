function colorrgb = A_colorpicker(colorlist,selection)
% SIMPLE_GUI2 Select a data set from the pop-up menu, then
% click one of the plot-type push buttons. Clicking the button
% plots the selected data in the axes.

%colors = {'ffcc99','ccff99','99ffcc','ccffff','ccccff','ffbbff','ffcccc','ffffcc','f0f0f0','ff0000','00ff00','0000ff'};
if nargin==2
    if isnumeric(selection)
        colorrgb = colorlist{selection+1};
        return
    end
    height = 330;
else
    height = 330;
end

colorrgb = nan;
%  Create and then hide the UI as it is being constructed.
f = figure('Visible','off','Position',[0,0,100,height]);
set(f, 'MenuBar', 'none');
set(f, 'ToolBar', 'none');



handles = {};
n = numel(colorlist);
if n>10
    n = 10;
end
for iColor = 1:n
    handles{iColor} = uicontrol('Style','pushbutton',...
            'BackgroundColor',colorlist{iColor},...
             'String','','Position',[0,height-25*iColor,110,25],...
             'Callback',{@setColor,iColor}); 
end
%custom 
handles{iColor} = uicontrol('Style','pushbutton',...
             'String','custom','Position',[0,height-25*(iColor+1),110,25],...
             'Callback',{@setCustomColor}); 
         

                
                
% Assign the a name to appear in the window title.
f.Name = 'SDK_ColorPicker';
% Move the window to the center of the screen.
movegui(f,'center')
% Make the window visible.
f.Visible = 'on';
uiwait(gcf)


    function setCustomColor(source,eventdata)
        colorrgb = uisetcolor;
        uiresume(gcf)
        close(gcf)
    end

   function setColor(source,eventdata,selectedcolor)
    uiresume(gcf)
    colorrgb = colorlist{selectedcolor};
    


    close(gcf)
   end

      
end
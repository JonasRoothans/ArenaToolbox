
classdef SamplingMethod
    properties
    end
    
    methods
        function obj = SamplingMethod(obj)
        end
        
        function ok = mapIsOk(obj,map)
            for required = 1:length(obj.RequiredHeatmaps)
                if isempty(map.(obj.RequiredHeatmaps{required}))
                    error(['Expected Heatmap: ',obj.RequiredHeatmaps{required}])
                end
            end
            ok = true; %all passed
        end
        
    end
    methods (Static)
        function [funclist,namelist,descriptionlist] = getMethods()
            path_of_this_class = fileparts(mfilename('fullpath'));
            methods  = A_getfiles(fullfile(path_of_this_class,'A_*.m'));
            funclist = {};
            namelist = {};
            descriptionlist = {};
            for i_method = 1:numel(methods)
                namelist{i_method} = methods(i_method).name(3:end-2);
                funclist{i_method} = str2func(['A_',namelist{i_method}]);
                instance = feval(funclist{i_method});
                descriptionlist{i_method} = instance.Description;
            end
        end
        
        function selectedmethod = choosedlg()
            %get info
            [funcs,names,descriptions] = SamplingMethod.getMethods();
            
            %make pop-up (based on listdlg)
            height = 400;
            fp = get(0,'DefaultFigurePosition');
            fig = figure('Position',[fp(1),fp(2),400,height],...
                'Resize','off',...
                'closerequestfcn' ,'delete(gcbf)',...
                'name','Arena - choose sampling method');
            text = uicontrol(fig,'Style','text',...
                'String','Choose your sampling method',...
                'Position',[10,height-40,380,20]);
            listbox = uicontrol('Style','listbox',...
                'Position',[10,height-200,380,150],...
                'String',names,...
                'BackgroundColor','w',...
                'Tag','listbox',...
                'Value',1, ...
                'Callback', {@doListboxClick});
            
            ok_btn = uicontrol('Style','pushbutton',...
                'String','choose',...
                'Position',[10,10,380,height-340],...
                'Tag','ok_btn',...
                'Callback',{@doOK,listbox});
            textDescription = uicontrol(fig,'Style','text',...
                'String',descriptions{1},...
                'Position',[10,height-320,380,100]);
            
            %---------   Callbacks
            function doListboxClick(listbox, evd, selectall_btn) %#ok
                % if this is a doubleclick, doOK
                if strcmp(get(gcbf,'SelectionType'),'open')
                    doOK([],[],listbox);
                else
                    textDescription.String = descriptions{get(listbox,'Value')};
                end
            end
            function doOK(ok_btn, evd,listbox) %#ok
                if (~isappdata(0, 'ListDialogAppData__'))
                    ad.value = 1;
                    ad.selection = get(listbox,'Value');
                    setappdata(0,'ListDialogAppData__',ad);
                    delete(gcbf);
                end
            end
            
            %----- get focus
            
            %setdefaultbutton(fig, ok_btn);
            % make sure we are on screen
            movegui(fig)
            set(fig, 'Visible','on'); drawnow;
            if ~isunix
            try
                % Give default focus to the listbox *after* the figure is made visible
                uicontrol(listbox);
                c = matlab.ui.internal.dialog.DialogUtils.disableAllWindowsSafely();
                uiwait(fig);
                delete(c);
            catch
                if ishghandle(fig)
                    delete(fig)
                end
            end
            else
                if ishandle(fig)
                    uiwait(fig)
                end
            end
            
            %fix the output
            if isappdata(0,'ListDialogAppData__')
                ad = getappdata(0,'ListDialogAppData__');
                selection = ad.selection;
                value = ad.value;
                rmappdata(0,'ListDialogAppData__')
                selectedmethod = funcs{selection};
            else
                % figure was deleted
                selection = [];
                selectedmethod = [];
                value = 0;
            end
            
            
            drawnow; % Update the view to remove the closed figure (g1031998)

            
        end
        
    end
end


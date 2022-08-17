function varargout = electrode(varargin)
% ELECTRODE MATLAB code for electrode.fig
%      ELECTRODE, by itself, creates a new ELECTRODE or raises the existing
%      singleton*.
%
%      H = ELECTRODE returns the handle to a new ELECTRODE or the handle to
%      the existing singleton*.
%
%      ELECTRODE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ELECTRODE.M with the given input arguments.
%
%      ELECTRODE('Property','Value',...) creates a new ELECTRODE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before electrode_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to electrode_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help electrode

% Last Modified by GUIDE v2.5 17-Aug-2022 11:19:57

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @electrode_OpeningFcn, ...
                   'gui_OutputFcn',  @electrode_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before electrode is made visible.
function electrode_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to electrode (see VARARGIN)

% Choose default command line output for electrode
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

if iscell(varargin{1})
    handles.uitable1.Data= varargin{1};
end

% UIWAIT makes electrode wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = electrode_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = 1;
uiresume


% --- Executes on button press in Save.
function Save_Callback(hObject, eventdata, handles)
% hObject    handle to Save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
assignin('base','electrodes',handles.uitable1.Data)
closereq(); 


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
 assignin('base','electrodes',nan)
closereq(); 


% --- Executes on button press in Import.
function Import_Callback(hObject, eventdata, handles)
% hObject    handle to Import (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
 basevariables = evalin('base','whos');
 list = {};
 for iB = 1:numel(basevariables)
     switch basevariables(iB).class
         case 'double'
         case 'cell'
         otherwise 
             continue
     end
     if prod(basevariables(iB).size)==12
         list{end+1} = basevariables(iB).name;
     end
         
 end
 
indx = listdlg('ListString',list);
data = evalin('base',list{indx});
if ~iscell(data)
    data = num2cell(data);
    data = cellfun(@num2str, data);
end
handles.uitable1.Data = data;



 
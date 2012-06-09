function varargout = VisualISAM_gui(varargin)
% VISUALISAM_GUI MATLAB code for VisualISAM_gui.fig
%      VISUALISAM_GUI, by itself, creates a new VISUALISAM_GUI or raises the existing
%      singleton*.
%
%      H = VISUALISAM_GUI returns the handle to a new VISUALISAM_GUI or the handle to
%      the existing singleton*.
%
%      VISUALISAM_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VISUALISAM_GUI.M with the given input arguments.
%
%      VISUALISAM_GUI('Property','Value',...) creates a new VISUALISAM_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before VisualISAM_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to VisualISAM_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help VisualISAM_gui

% Last Modified by GUIDE v2.5 08-Jun-2012 23:53:47

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @VisualISAM_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @VisualISAM_gui_OutputFcn, ...
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


% --- Executes just before VisualISAM_gui is made visible.
function VisualISAM_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to VisualISAM_gui (see VARARGIN)

% Choose default command line output for VisualISAM_gui
initOptions(handles)
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes VisualISAM_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);

function showFramei(hObject, handles)
    VisualISAMGlobalVars
    set(handles.frameStatus, 'String', sprintf('Frame: %d',frame_i));
    drawnow
    guidata(hObject, handles);
    
function showWaiting(handles, status)
    set(handles.waitingStatus,'String', status);
    drawnow
    guidata(handles.waitingStatus, handles);
    
function triangle = chooseDataset(handles)
	str = cellstr(get(handles.dataset,'String'));
    sel = get(handles.dataset,'Value');
    switch str{sel}
        case 'triangle'
            triangle = true;
        case 'cube'
            triangle = false;
    end
    
function initOptions(handles)
    VisualISAMGlobalVars
    %% Setting data options
    TRIANGLE = chooseDataset(handles)
    NCAMERAS = str2num(get(handles.numCamEdit,'String')) 
    SHOW_IMAGES = get(handles.showImagesCB,'Value')

    %% iSAM Options
    HARD_CONSTRAINT = get(handles.hardConstraintCB,'Value')
    POINT_PRIORS = get(handles.pointPriorsCB,'Value')
    set(handles.batchInitCB,'Value',1);
    drawnow
    BATCH_INIT = get(handles.batchInitCB,'Value')
    REORDER_INTERVAL = str2num(get(handles.numCamEdit,'String')) 
    ALWAYS_RELINEARIZE = get(handles.alwaysRelinearizeCB,'Value')

    %% Display Options
    SAVE_GRAPH = get(handles.saveGraphCB,'Value')
    PRINT_STATS = get(handles.printStatsCB,'Value')
    DRAW_INTERVAL = str2num(get(handles.drawInterval,'String'))
    CAMERA_INTERVAL = str2num(get(handles.cameraIntervalEdit,'String')) 
    DRAW_TRUE_POSES = get(handles.drawTruePosesCB,'Value')
    SAVE_FIGURES = get(handles.saveFiguresCB,'Value')
    SAVE_GRAPHS = get(handles.saveGraphsCB,'Value')

% --- Outputs from this function are returned to the command line.
function varargout = VisualISAM_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in intializeButton.
function intializeButton_Callback(hObject, eventdata, handles)
% hObject    handle to intializeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    VisualISAMGlobalVars
    initOptions(handles)
    VisualISAMGenerateData
    VisualISAMInitialize
    VisualISAMPlot
    showFramei(hObject, handles)
    
    
% --- Executes on button press in stepButton.
function stepButton_Callback(hObject, eventdata, handles)
% hObject    handle to stepButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    VisualISAMGlobalVars
    if (frame_i<NCAMERAS)
        frame_i = frame_i+1;
        showFramei(hObject, handles)
        VisualISAMStep
        if mod(frame_i,DRAW_INTERVAL)==0
            showWaiting(handles, 'Computing marginals...');
            VisualISAMPlot
            showWaiting(handles, '');
        end
    end

% --- Executes on selection change in dataset.
function dataset_Callback(hObject, eventdata, handles)
% hObject    handle to dataset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns dataset contents as cell array
%        contents{get(hObject,'Value')} returns selected item from dataset
    

% --- Executes during object creation, after setting all properties.
function dataset_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dataset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in runButton.
function runButton_Callback(hObject, eventdata, handles)
% hObject    handle to runButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    VisualISAMGlobalVars
    while (frame_i<NCAMERAS)
        frame_i = frame_i+1;
        showFramei(hObject, handles)
        VisualISAMStep
        if mod(frame_i,DRAW_INTERVAL)==0
            showWaiting(handles, 'Computing marginals...');
            VisualISAMPlot
            showWaiting(handles, '');
        end
    end

% --- Executes on button press in plotButton.
function plotButton_Callback(hObject, eventdata, handles)
% hObject    handle to plotButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    VisualISAMPlot;


% --- Executes during object creation, after setting all properties.
function drawInterval_CreateFcn(hObject, eventdata, handles)
% hObject    handle to drawInterval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function numCamEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numCamEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function reorderIntervalText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to reorderIntervalText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function cameraIntervalEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cameraIntervalEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function reorderIntervalEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to reorderIntervalEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function numCamEdit_Callback(hObject, eventdata, handles)
% hObject    handle to numCamEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numCamEdit as text
%        str2double(get(hObject,'String')) returns contents of numCamEdit as a double


% --- Executes on button press in showImagesCB.
function showImagesCB_Callback(hObject, eventdata, handles)
% hObject    handle to showImagesCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showImagesCB


% --- Executes on button press in hardConstraintCB.
function hardConstraintCB_Callback(hObject, eventdata, handles)
% hObject    handle to hardConstraintCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hardConstraintCB


% --- Executes on button press in pointPriorsCB.
function pointPriorsCB_Callback(hObject, eventdata, handles)
% hObject    handle to pointPriorsCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of pointPriorsCB


% --- Executes on button press in batchInitCB.
function batchInitCB_Callback(hObject, eventdata, handles)
% hObject    handle to batchInitCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of batchInitCB


% --- Executes on button press in alwaysRelinearizeCB.
function alwaysRelinearizeCB_Callback(hObject, eventdata, handles)
% hObject    handle to alwaysRelinearizeCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of alwaysRelinearizeCB



function drawInterval_Callback(hObject, eventdata, handles)
% hObject    handle to drawInterval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of drawInterval as text
%        str2double(get(hObject,'String')) returns contents of drawInterval as a double



function cameraIntervalEdit_Callback(hObject, eventdata, handles)
% hObject    handle to cameraIntervalEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cameraIntervalEdit as text
%        str2double(get(hObject,'String')) returns contents of cameraIntervalEdit as a double


% --- Executes on button press in saveGraphCB.
function saveGraphCB_Callback(hObject, eventdata, handles)
% hObject    handle to saveGraphCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of saveGraphCB


% --- Executes on button press in printStatsCB.
function printStatsCB_Callback(hObject, eventdata, handles)
% hObject    handle to printStatsCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of printStatsCB


% --- Executes on button press in drawTruePosesCB.
function drawTruePosesCB_Callback(hObject, eventdata, handles)
% hObject    handle to drawTruePosesCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of drawTruePosesCB


% --- Executes on button press in saveFiguresCB.
function saveFiguresCB_Callback(hObject, eventdata, handles)
% hObject    handle to saveFiguresCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of saveFiguresCB


% --- Executes on button press in saveGraphsCB.
function saveGraphsCB_Callback(hObject, eventdata, handles)
% hObject    handle to saveGraphsCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of saveGraphsCB

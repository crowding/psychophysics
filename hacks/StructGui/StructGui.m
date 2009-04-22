function varargout = StructGui(varargin)
% STRUCTGUI M-file for StructGui.fig
%      Interactive gui to set the values in a structure 
%      RES = STRUCTGUI('title',STRING, 'range',STRUCT1, 'settings',STRUCT2,
%      'help', STRUCT3). The arguments must be supplied in couples property
%      - value. The allowed Properties are: 
%      
%      'title': Optional property for which STRING is a string representing
%      the title of the window. When this property is not set, the filename
%      'StructGui' is used as default.
%       
%      'range': this is a complulsory property. The corresponding STRUCT1 is
%      a structure representing the allowed range for structure STRUCT2,
%      passed with the property 'settings'. Each field can be a cell array,
%      where optionally, the first row represent a string to be shown in
%      the gui, and the second row the allowed value for the setting
%      structure STRUCT2. When just a row of values is provided, it
%      represent both the value allowed for STRUCT2 and the string shown in
%      the gui window.
%
%      'settings': set the structure STRUCT2 to be modified.
%
%      'help': is a 1-by-2 structure that set the help string for each
%      field and item of the structure passed with the 'range' property.
%      The help string for each field of STRUCT1 shown in a listbox of the
%      gui, is in the first element of the structure passed: STRUCT3(1).
%      The help string for each item corresponding to a field, shown as a
%      radio button in the gui, is on the second element of the structure
%      passed: STRUCT3(2).
%
%      RES returns the updated structure supplied in 'settings'. Choosing
%      'yes' in the gui to update the 'settings' structure, choose 'No', to
%      return same structure provided in 'settings'. If the property
%      'settings' was not passed, the first item in each fields of the
%      property 'range' is returned. It is an optional property.
%     
%      Example:
%      r = struct('field1',{{'y','n'}}, 'field2',{{'first', 'second';1,2}}, ...
%          'field3',{{'A', 'B', 'C';[1 3],[2 3 4],[3 6 9 12]}}, 'field4',{{1, 2, 3}}, ...
%          'field5',{{'yes', 'no'; 'y', 'n'}});
%      x = struct('field1','y','field2',{2},'field3',[1 3],'field4', 2);
%      h = struct('field1',{'help f1', {'item1a', 'item1b'}}, ...
%          'field2',{'help f2', {'item2a', 'item2b'}},'field3',{'', {'item3a', 'item3b'}});
%      y = StructGui('title','Input your choice', 'range',r, 'settings',x, 'help', h);
%
%      also allowed:
%
%      y = StructGui('range',r);
%      x = StructGui('title','Input your choice', 'settings',x, 'range',r);
%      y = StructGui('settings',x, 'range',r);
%      y = StructGui('title','Input your choice', 'range',r);

% Edit the above text to modify the response to help StructGui

% Last Modified by GUIDE v2.5 15-Jun-2004 08:24:58

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @StructGui_OpeningFcn, ...
    'gui_OutputFcn',  @StructGui_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin & isstr(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before StructGui is made visible.
function StructGui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to StructGui (see VARARGIN)

% Choose default command line output for StructGui
handles.output = 'Yes';

% Update handles structure
guidata(hObject, handles);

% Insert custom Title and Text if specified by the user
% Hint: when choosing keywords, be sure they are not easily confused 
% with existing figure properties.  See the output of set(figure) for
% a list of figure properties.
error(nargchk(3,11,nargin));
if(nargin > 3)
    if rem (nargin-3, 2 ) ~= 0
        error( 'Optional initialization arguments must be passed in pairs' );
    end
    
    err_prop = varargin(1:2:nargin-4);
    err_memb = ismember(err_prop,{'title','range','settings','help'});
    
    if ~all(err_memb)  
        error(sprintf('Property ''%s''  is not valid\n',err_prop{~err_memb}))
    end
                
    data = guidata(handles.figStructGui);
    for index = 1:2:(nargin-3),
        if nargin-3 == index break, end
        switch lower(varargin{index})
            case 'title'
                set(hObject, 'Name', varargin{index+1});
            case 'range'
                data.range = varargin{index+1};
            case 'settings'
                data.settings = varargin{index+1};
            case {'help'}
                switch length(varargin{index+1})
                    case 1
                        data.fhelp = varargin{index+1}(1);
                    case 2
                        [data.fhelp, data.ihelp] = deal(varargin{index+1}(1),varargin{index+1}(2)); 
                    otherwise
                        error('Size of help structure is wrong')
                end
            otherwise
                %
        end
    end
    if ~isfield(data,'range'),error('range property must be provided'), end 
    
    ifields = fields(data.range);
    nfields = length(ifields);
    
    if ~isfield(data,'settings')
        data.settings = data.range;
        for i =1:nfields
            data.settings.(ifields{i}) = data.range.(ifields{i}){end,1};
        end
    end 
    
    data.save_settings = data.settings;
    if isfield(data,'fhelp')
        f = setdiff(ifields,fields(data.fhelp));
        for i = 1:length(f)
            data.fhelp.(f{i}) = '';
        end
    end
    
    guidata(handles.figStructGui, data);
    set(handles.listSettingsFields,'String',fields(data.range))
    listSettingsFields_Callback(handles.listSettingsFields,[],handles);
else
    error('Insufficent number of parameters!!!')
end

% Determine the position of the dialog - centered on the callback figure
% if available, else, centered on the screen
FigPos=get(0,'DefaultFigurePosition');
OldUnits = get(hObject, 'Units');
set(hObject, 'Units', 'pixels');
OldPos = get(hObject,'Position');
FigWidth = OldPos(3);
FigHeight = OldPos(4);
if isempty(gcbf)
    ScreenUnits=get(0,'Units');
    set(0,'Units','pixels');
    ScreenSize=get(0,'ScreenSize');
    set(0,'Units',ScreenUnits);
    
    FigPos(1)=1/2*(ScreenSize(3)-FigWidth);
    FigPos(2)=2/3*(ScreenSize(4)-FigHeight);
else
    GCBFOldUnits = get(gcbf,'Units');
    set(gcbf,'Units','pixels');
    GCBFPos = get(gcbf,'Position');
    set(gcbf,'Units',GCBFOldUnits);
    FigPos(1:2) = [(GCBFPos(1) + GCBFPos(3) / 2) - FigWidth / 2, ...
            (GCBFPos(2) + GCBFPos(4) / 2) - FigHeight / 2];
end
FigPos(3:4)=[FigWidth FigHeight];
set(hObject, 'Position', FigPos);
set(hObject, 'Units', OldUnits);

% Make the GUI modal
set(handles.figStructGui,'WindowStyle','normal')

% UIWAIT makes StructGui wait for user response (see UIRESUME)
uiwait(handles.figStructGui);

% --- Outputs from this function are returned to the command line.
function varargout = StructGui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure

if nargout
    data = guidata(handles.figStructGui);
    switch handles.output
        case 'Yes'
            varargout{1} = data.settings;
        case 'No'
            varargout{1} = data.save_settings;
        otherwise
            varargout{1} = [];
    end
else 
    varargout{1} = [];
end

% The figure can be deleted now
delete(handles.figStructGui);

% --- Executes on button press in buttonYes.
function buttonYes_Callback(hObject, eventdata, handles)
% hObject    handle to buttonYes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.output = get(hObject,'String');

% Update handles structure
guidata(hObject, handles);

% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.figStructGui);

% --- Executes on button press in buttonNO.
function buttonNO_Callback(hObject, eventdata, handles)
% hObject    handle to buttonNO (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.output = get(hObject,'String');

% Update handles structure
guidata(hObject, handles);

% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.figStructGui);


% --- Executes when user attempts to close figStructGui.
function figStructGui_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figStructGui (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isequal(get(handles.figStructGui, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, us UIRESUME
    uiresume(handles.figStructGui);
else
    % The GUI is no longer waiting, just close it
    delete(handles.figStructGui);
end


% --- Executes on key press over figStructGui with no controls selected.
function figStructGui_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figStructGui (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Check for "enter" or "escape"
if isequal(get(hObject,'CurrentKey'),'escape')
    % User said no by hitting escape
    handles.output = 'No';
    
    % Update handles structure
    guidata(hObject, handles);
    
    uiresume(handles.figStructGui);
end    

if isequal(get(hObject,'CurrentKey'),'return')
    uiresume(handles.figStructGui);
end    


% --- Executes during object creation, after setting all properties.
function listSettingsFields_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listSettingsFields (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --- Executes on selection change in listSettingsFields.
function listSettingsFields_Callback(hObject, eventdata, handles)
% hObject    handle to listSettingsFields (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns listSettingsFields contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listSettingsFields

try
    ItemListValue = get(hObject,'Value');
    data = guidata(handles.figStructGui);
    
    fieldsNames = fields(data.range);
    rButtonTags = data.range.(fieldsNames{ItemListValue});
    
    if ~ismember(fieldsNames{ItemListValue},fields(data.settings))
        data.settings.(fieldsNames{ItemListValue}) = data.range.(fieldsNames{ItemListValue}){end,1};
        guidata(handles.figStructGui, data);
    end
    
    rButtonVal =  data.settings.(fieldsNames{ItemListValue});
    
    switch class(rButtonVal)
        case 'char'
            ItemSettingValue = strmatch(rButtonVal, rButtonTags(end,:),'exact');
        case 'cell'
            ItemSettingValue = strmatch(deblank(sprintf('%d ',rButtonVal{:})),rButtonTags(size(rButtonTags,1),:),'exact');      
        otherwise %isnumeric
            switch length(rButtonVal)
                case 1
                    ItemSettingValue = find([rButtonTags{size(rButtonTags,1),:}] == rButtonVal );
                otherwise
                    for ItemSettingValue = 1:size(rButtonTags,2)
                        if isequal(rButtonTags{2,ItemSettingValue},rButtonVal), break, end
                    end
            end
    end
    
    tts = cell([1 size(data.range.(fieldsNames{ItemListValue}),2)]);
    [tts{:}] = deal('');
    if isfield(data,'ihelp') && isfield(data.ihelp, fieldsNames{ItemListValue})
        [tts(1:length(data.ihelp.(fieldsNames{ItemListValue})))] = deal(data.ihelp.(fieldsNames{ItemListValue}));
    end
    
    eventdata = struct('rButtonVal', rButtonVal,...
        'rButtonTags',{rButtonTags(1,:)},...
        'ItemSettingValue', ItemSettingValue, ...
        'TooltipString', {tts});
    
    radiob_CreateFcn(handles.frameStructGui ,eventdata ,handles);
    if isfield(data,'fhelp')
        set(handles.listSettingsFields, 'TooltipString', data.fhelp.(fieldsNames{ItemListValue}))
    end
    
catch
    errordlg(lasterr,'StructGui:RCSetRadiobItems');
end

function radiob_Callback(hObject, eventdata, handles)
% hObject    handle to listSettingsFields (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns listSettingsFields contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listSettingsFields

hRadiob = getappdata(handles.figStructGui,'radiob');
set(hRadiob,'Value',0);
set(hObject, 'Value',1);

ItemSettingValue = find(hRadiob == hObject);
ItemListValue = get(handles.listSettingsFields,'Value');
data = guidata(handles.figStructGui);

fieldsNames = fields(data.settings);
valueRow = size(data.range.(char(fieldsNames(ItemListValue))),1);
if isa(data.settings.(char(fieldsNames(ItemListValue))),'numeric')
    data.settings.(char(fieldsNames(ItemListValue))) =  data.range.(char(fieldsNames(ItemListValue))){valueRow, ItemSettingValue}; 
else
    data.settings.(char(fieldsNames(ItemListValue))) =  char(data.range.(char(fieldsNames(ItemListValue)))(valueRow, ItemSettingValue)); 
end

guidata(handles.figStructGui, data);

function radiob_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listSettingsFields (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns listSettingsFields contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listSettingsFields

FramePosition = get(hObject,'Position');
ItemPosition = FramePosition + [1 ... % left
        FramePosition(4)-.5 ...       % bottom
        -2 ...                        % width 
        1.5 - FramePosition(4)];      % height

nitems = length(eventdata.rButtonTags);
itemsgap = FramePosition(4)/(nitems+1);

if isappdata(handles.figStructGui,'radiob');
    delete(getappdata(handles.figStructGui,'radiob'))
    rmappdata(handles.figStructGui,'radiob')
end

for j=1:nitems
    ItemPosition(2)=ItemPosition(2) - itemsgap;        
    radiob(j) = uicontrol('Style', 'radiobutton',...
        'String',  eventdata.rButtonTags(1,j),...
        'Units','Characters',...
        'Position', ItemPosition,...
        'Callback', 'StructGui(''radiob_Callback'',gcbo,[],guidata(gcbo))',...
        'TooltipString', eventdata.TooltipString{j}, ...
        'Tag', ['radiob' int2str(j)] );
end  
setappdata(handles.figStructGui,'radiob',radiob);
set(radiob(eventdata.ItemSettingValue), 'Value',1);


% --- Executes on mouse press over figure background.
function figStructGui_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to figStructGui (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



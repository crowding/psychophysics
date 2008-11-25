function hFig = uiinspect(obj)
% uiinspect Inspect an object handle (Java/COM/HG) and display its methods/props/callbacks in a unified window
%
% Syntax:
%    hFig = uiinspect(obj)
%
% Description:
%    UIINSPECT inspects an object handle (e.g., Java, COM, Handle Graphics
%    etc.) and displays the inspection results in a unified Matlab window.
%    UIINSPECT displays a unified window with all relevant object methods
%    (as can be displayed via Matlab's methodsview function), properties
%    (as can be displayed via Matlab's inspect function), and callbacks.
%    UIINSPECT also displays properties that are not normally displayed
%    with Matlab's inspect function. Property meta-data such as type,
%    accessibility, visibility and default value are also displayed.
%
%    Unlike Matlab's inspect function, multiple UIINSPECT windows can be
%    opened simultaneously.
%
%    Object properties and callbacks may be modified interactively within
%    the UIINSPECT window.
%
%    hFig = UIINSPECT returns a handle to the created figure window.
%    UIINSPECT opens a regular Matlab figure window which may be accessed
%    via hFig (unlike Matlab's methodsview function which opens a Java frame
%    that is not easily accessible from Matlab).
%
% Examples:
%    hFig = uiinspect(0);              % root (desktop)
%    hFig = uiinspect(handle(0));      % root handle
%    hFig = uiinspect(gcf);            % current figure
%    hFig = uiinspect(handle(gcf));    % current figure handle
%    uiinspect(get(gcf,'JavaFrame'));  % current figure's Java Frame
%    uiinspect(classhandle(handle(gcf)));         % a schema.class object
%    uiinspect(findprop(handle(gcf),'MenuBar'));  % a schema.prop object
%    uiinspect(java.lang.String('yes'));          % a Java object
%    uiinspect(actxserver('Excel.Application'));  % a COM object
%
% Known issues/limitations:
%    - Fix: some fields generate a Java Exception, or a Matlab warning
%    - other future enhancements may be found in the TODO list below
%
% Warning:
%    This code heavily relies on undocumented and unsupported Matlab functionality.
%    It works on Matlab 7+, but use at your own risk!
%
% Bugs and suggestions:
%    Please send to Yair Altman (altmany at gmail dot com)
%
% Change log:
%    2007-12-08: First version posted on <a href="http://www.mathworks.com/matlabcentral/fileexchange/loadAuthor.do?objectType=author&mfx=1&objectId=1096533#">MathWorks File Exchange</a>
%    2008-01-25: Fixes for many edge-cases
%
% See also:
%    ishandle, iscom, inspect, methodsview, FindJObj (on the File Exchange)

% License to use and modify this code is granted freely to all interested, as long as the original author is
% referenced and attributed as such. The original author maintains the right to be solely associated with this work.

% Programmed by Yair M. Altman: altmany(at)gmail.com
% $Revision: 1.1 $  $Date: 2008/01/25 14:46:12 $

  try
      % Arg check
      error(nargchk(1,1,nargin));
      if ~ishandle(obj)
          myError('YMA:uiinspect:notAHandle','Input to uiinspect must be a valid object as defined by ISHANDLE');
      elseif numel(obj) ~= 1
          myError('YMA:uiinspect:notASingleton','Input to uiinspect must be a single object handle');
      end

      % Get object data
      objMethods   = getObjMethods(obj);
      objProps     = getObjProps(obj);
      objCallbacks = getObjCallbacks(obj);
      objChildren  = getObjChildren(obj);
      
      % Display object data
      fig = displayObj(obj, objMethods, objProps, objCallbacks, objChildren, inputname(1));
      if nargout,  hFig = fig;  end
% {
  % Error handling
  catch
      v = version;
      if v(1)<='6'
          err.message = lasterr;  % no lasterror function...
      else
          err = lasterror;
      end
      try
          err.message = regexprep(err.message,'Error using ==> [^\n]+\n','');
      catch
          try
              % Another approach, used in Matlab 6 (where regexprep is unavailable)
              startIdx = findstr(err.message,'Error using ==> ');
              stopIdx = findstr(err.message,char(10));
              for idx = length(startIdx) : -1 : 1
                  idx2 = min(find(stopIdx > startIdx(idx)));  %#ok ML6
                  err.message(startIdx(idx):stopIdx(idx2)) = [];
              end
          catch
              % never mind...
          end
      end
      if isempty(findstr(mfilename,err.message))
          % Indicate error origin, if not already stated within the error message
          err.message = [mfilename ': ' err.message];
      end
      if v(1)<='6'
          while err.message(end)==char(10)
              err.message(end) = [];  % strip excessive Matlab 6 newlines
          end
          error(err.message);
      else
          rethrow(err);
      end
  end
% }

%% Internal error processing
function myError(id,msg)
    v = version;
    if (v(1) >= '7')
        error(id,msg);
    else
        % Old Matlab versions do not have the error(id,msg) syntax...
        error(msg);
    end
%end  % myError  %#ok for Matlab 6 compatibility

%% Get object data - methods
function objMethods = getObjMethods(obj)

    % The following was taken from Matlab's methodsview function
    qcls = builtin('class', obj);
    [m,d] = methods(obj,'-full');
    dflag = 1;
    ncols = 6;

    if isempty(d),
        dflag = 0;
        d = cell(size(m,1), ncols);
        for i=1:size(m,1),
            t = find(m{i}=='%',1,'last');
            if ~isempty(t),
                d{i,3} = m{i}(1:t-2);
                d{i,6} = m{i}(t+17:end);
            else
                d{i,3} = m{i};
            end;
        end;
    end;

    r = size(m,1);
    t = d(:,4);
    d(:,4:ncols-1) = d(:,5:ncols);
    d(:,ncols) = t;
    [y,x] = sort(d(:,3));%#ok
    cls = '';
    clss = 0;

    w = num2cell(zeros(1,ncols));

    for i=1:r,
        if isempty(cls) && ~isempty(d{i,6}),
            t = find(d{i,6}=='.', 1, 'last');
            if ~isempty(t),
                if strcmp(d{i,3},d{i,6}(t+1:end)),
                    cls = d{i,6};
                    clss = length(cls);
                end;
            end;
        end;
        for j=1:ncols
            if isnumeric(d{i,j}),
                d{i,j} = '';
            end;
            if j==4 && strcmp(d{i,j},'()'),
                d{i,j} = '( )';
            else
                if j==6,
                    d{i,6} = deblank(d{i,6});
                    if clss > 0 && ...
                            (strncmp(d{i,6},qcls,length(qcls)) || ... %Yair
                            (strncmp(d{i,6},cls,clss) &&...
                            (length(d{i,6}) == clss ||...
                            (length(d{i,6}) > clss && d{i,6}(clss+1) == '.'))))
                        d{i,6} = '';
                    else
                        if ~isempty(d{i,6}),
                            t = find(d{i,6}=='.', 1, 'last');
                            if ~isempty(t),
                                d{i,6} = d{i,6}(1:t-1);
                            end;
                        end
                    end;
                end;
            end;
        end;
    end;

    if ~dflag,
        for i=1:r,
            d{i,6} = d{i,5};
            d{i,5} = '';
        end;
    end;

    datacol = zeros(1, ncols);
    for i=1:r,
        for j=1:ncols
            if ~isempty(d{i,j}),
                datacol(j) = 1;
                w{j} = max(w{j},length(d{i,j}));
            end;
        end;
    end;

    % Determine the relevant column headers (& widths)
    ch = {};
    hdrs = {'Qualifiers', 'Return Type', 'Name', 'Arguments', 'Other', 'Inherited From'};
    for i=ncols:-1:1,
        if datacol(i),
            datacol(i) = sum(datacol(1:i));
            ch{datacol(i)} = hdrs{i};  %#ok
            w{i} = max([length(ch{datacol(i)}),w{i}]);
        end;
    end;

    if isempty(ch)
        ch = ' ';
        d = {'(no methods)'};
        w = {100};
        x = 1;
        datacol = 1;
    end

    % Return the data
    objMethods.headers = ch;
    objMethods.methods = d(:,find(datacol));  %#ok for ML6 compatibility
    objMethods.widths  = [w{find(datacol)}];  %#ok for ML6 compatibility
    objMethods.sortIdx = x;
%end  % getObjMethods

%% Get object data - properties
function objProps = getObjProps(obj)
    objProps = obj;  %TODO - merge with getPropsData() below
%end  % getObjProps

%% Get object data - callbacks
function objCallbacks = getObjCallbacks(obj)
    objCallbacks = obj;  %TODO - merge with getCbsData() below
%end  % getObjCallbacks

%% Get object data - children
function objChildren = getObjChildren(obj)
    objChildren = obj;  %TODO - merge with getPropsData() below
%end  % getObjChildren

%% Display object data
function hFig = displayObj(obj, objMethods, objProps, objCallbacks, objChildren, objName)

      % Prepare the data panes
      methodsPane = getMethodsPane(objMethods, obj);
      [callbacksPanel, cbTable] = getCbsPane(objCallbacks, false);
      [propsPane, inspectorTable] = getPropsPane(objProps);
      childrenPane = getChildrenPane(objChildren, inspectorTable);

      % Prepare the top-bottom JSplitPanes
      import java.awt.* javax.swing.*
      rightPanel = JSplitPane(JSplitPane.VERTICAL_SPLIT, propsPane, childrenPane);
      leftPanel  = JSplitPane(JSplitPane.VERTICAL_SPLIT, methodsPane, callbacksPanel);
      set(rightPanel, 'OneTouchExpandable','on', 'ContinuousLayout','on', 'ResizeWeight',0.8);
      set(leftPanel,  'OneTouchExpandable','on', 'ContinuousLayout','on', 'ResizeWeight',0.7);

      % Prepare the left-right JSplitPane
      hsplitPane = JSplitPane(JSplitPane.HORIZONTAL_SPLIT, leftPanel, rightPanel);
      set(hsplitPane,'OneTouchExpandable','on','ContinuousLayout','on','ResizeWeight',0.6);

      % Display on-screen
      globalPanel = JPanel(BorderLayout);
      globalPanel.add(hsplitPane, BorderLayout.CENTER);
      hFig = figure;
      if isempty(objName),  objName = 'object';  end
      title = ['uiinspect: ' objName ' of class ' builtin('class',obj)];
      set(hFig, 'Name',title, 'NumberTitle','off', 'units','pixel', 'toolbar','none');
      pos = get(hFig,'position');
      [obj, hcontainer] = javacomponent(globalPanel, [0,0,pos(3:4)], hFig);
      set(hcontainer,'units','normalized');
      drawnow;

      % this only works after the JSplitPane is displayed...
      hDivPos = 0.6;
      if length(objMethods.widths) < 3
          hDivPos = 0.4;
      end
      hsplitPane.setDividerLocation(hDivPos);

      vDivPos = 0.8;  try  vDivPos = max(0.2,min(vDivPos,inspectorTable.getRowCount/10));  catch end
      rightPanel.setDividerLocation(vDivPos);

      vDivPos = max(0.8, 1-cbTable.getRowCount/10);
      try  vDivPos = max(0.3,min(vDivPos,length(objMethods.methods)/10));  catch end
      leftPanel.setDividerLocation(vDivPos);
      %restoreDbstopError(identifiers);

      return;  % debugable point
%end  % displayObj

%% Prepare the property inspector panel
function [propsPane, inspectorTable] = getPropsPane(obj)
      % Prepare the properties pane
      import java.awt.* javax.swing.*
      %classNameLabel = JLabel(['      ' char(obj.class)]);
      classNameLabel = JLabel('      Inspectable object properties');
      classNameLabel.setForeground(Color.blue);
      objProps = updateObjTooltip(obj, classNameLabel);  %#ok unused
      propsPane = JPanel(BorderLayout);
      propsPane.add(classNameLabel, BorderLayout.NORTH);
      % TODO: Maybe uncomment the following - in the meantime it's unused (java properties are un-groupable)
      %objReg = com.mathworks.services.ObjectRegistry.getLayoutRegistry;
      %toolBar = awtinvoke('com.mathworks.mlwidgets.inspector.PropertyView$ToolBarStyle','valueOf(Ljava.lang.String;)','GROUPTOOLBAR');
      %inspectorPane = com.mathworks.mlwidgets.inspector.PropertyView(objReg, toolBar);
      inspectorPane = com.mathworks.mlwidgets.inspector.PropertyView;
      identifiers = disableDbstopError;  %#ok "dbstop if error" causes inspect.m to croak due to a bug - so workaround
      inspectorPane.setObject(obj);
      inspectorPane.setAutoUpdate(true);
      % TODO: Add property listeners
      inspectorTable = inspectorPane;
      while ~isa(inspectorTable,'javax.swing.JTable')
          inspectorTable = inspectorTable.getComponent(0);
      end
      toolTipText = 'hover mouse over the blue label above to see the full list of properties';
      inspectorTable.setToolTipText(toolTipText);
      try
          % Try JIDE features - see http://www.jidesoft.com/products/JIDE_Grids_Developer_Guide.pdf
          com.mathworks.mwswing.MJUtilities.initJIDE;
          jideTableUtils = eval('com.jidesoft.grid.TableUtils;');  % prevent JIDE alert by run-time (not load-time) evaluation
          jideTableUtils.autoResizeAllColumns(inspectorTable);
          inspectorTable.setRowAutoResizes(true);
          inspectorTable.getModel.setShowExpert(1);
      catch
          % JIDE is probably unavailable - never mind...
      end
      propsPane.add(inspectorPane, BorderLayout.CENTER);
      %mainPropsPane = JPanel;
      %mainPropsPane.setLayout(BoxLayout(mainPropsPane, BoxLayout.PAGE_AXIS));
      %mainPropsPane.add(inspectorPane);

      % Strip all inspected props from objProps:
      pause(0.1);  %allow the inspector time to load...
      return;
      %{
      rows = inspectorTable.getModel.getRows;
      numRows = rows.size;
      for rowIdx = 0 : numRows-1
          thisRow = rows.get(rowIdx);
          objProps = stripProp(objProps, char(thisRow.getDisplayName));
          for childIdx = 0 : thisRow.getChildrenCount-1
              objProps = stripProp(objProps, char(thisRow.getChildAt(childIdx).getDisplayName));
          end
      end
      %}
%end  % getPropsPane

%% Strip inspected property name from pre-fetched list of object properties
function objProps = stripProp(objProps, inspectedPropName)  %#ok unused
      try
          % search for a case-insensitive match
          %objProps = rmfield(objProps,inspectedPropName);
          propNames = fieldnames(objProps);
          idx = strcmpi(propNames,inspectedPropName);
          objProps = rmfield(objProps,propNames(idx));
      catch
          % never mind - inspectedProp was probably not in objProps
      end
%end  % stripPropName

%% Get callbacks table data
function [cbData, cbHeaders, cbTableEnabled] = getCbsData(obj, stripStdCbsFlag)
      classHdl = classhandle(handle(obj));
      cbNames = get(classHdl.Events,'Name');
      if ~isempty(cbNames) && ~iscom(obj)  %only java-based please...
          cbNames = strcat(cbNames,'Callback');
      end
      propNames = get(classHdl.Properties,'Name');
      propCbIdx = [];
      if ~isempty(propNames)
          propCbIdx = find(~cellfun(@isempty,regexp(propNames,'(Fcn|Callback)$')));
          cbNames = unique([cbNames; propNames(propCbIdx)]);  %#ok logical is faster but less debuggable...
      end
      if ~isempty(cbNames)
          if stripStdCbsFlag
              cbNames = stripStdCbs(cbNames);
          end
          if iscell(cbNames)
              cbNames = sort(cbNames);
          end
          hgHandleFlag = 0;  try hgHandleFlag = ishghandle(obj); catch end
          try
              obj = handle(obj,'CallbackProperties');
          catch
              hgHandleFlag = 1;
          end
          if hgHandleFlag
              % HG handles don't allow CallbackProperties - search only for *Fcn
              cbNames = propNames(propCbIdx);
          end
          if iscom(obj)
              cbs = obj.eventlisteners;
              if ~isempty(cbs)
                  cbNamesRegistered = cbs(:,1);
                  cbData = setdiff(cbNames,cbNamesRegistered);
                  %cbData = charizeData(cbData);
                  if size(cbData,2) > size(cbData(1))
                      cbData = cbData';
                  end
                  cbData = [cbData, cellstr(repmat(' ',length(cbData),1))];
                  cbData = [cbData; cbs];
                  [sortedNames, sortedIdx] = sort(cbData(:,1));
                  sortedCbs = cellfun(@charizeData,cbData(sortedIdx,2),'un',0);
                  cbData = [sortedNames, sortedCbs];
              else
                  cbData = [cbNames, cellstr(repmat(' ',length(cbNames),1))];
              end
          elseif iscell(cbNames)
              %cbData = [cbNames, get(obj,cbNames)'];
              cbData = cbNames;
              for idx = 1 : length(cbNames)
                  try
                      cbData{idx,2} = charizeData(get(obj,cbNames{idx}));
                  catch
                      cbData{idx,2} = '(callback value inaccessible)';
                  end
              end
          else  % only one event callback
              %cbData = {cbNames, get(obj,cbNames)'};
              %cbData{1,2} = charizeData(cbData{1,2});
              try
                  cbData = {cbNames, charizeData(get(obj,cbNames))};
              catch
                  cbData = {cbNames, '(callback value inaccessible)'};
              end
          end
          cbHeaders = {'Callback name','Callback value'};
          cbTableEnabled = true;
      else
          cbData = {'(no callbacks)'};
          cbHeaders = {'Callback name'};
          cbTableEnabled = false;
      end
%end  % getCbsData

%% Get properties table data
function [propsData, propsHeaders, propTableEnabled] = getPropsData(obj, showMetaData, showInspectedPropsFlag, inspectorTable)
      try
          classHdl = classhandle(handle(obj));
          propNames = get(classHdl.Properties,'Name');
          %propsData = cell(0,7);
          propsData = {'(no properties)','','','','','',''};
          propsHeaders = {'Name','Type','Value','Get','Set','Visible','Default'};
          propTableEnabled = false;
          if ~isempty(propNames)

              if ~showInspectedPropsFlag
                  % Strip all inspected props
                  pause(0.01);  %allow the inspector time to load...
                  rows = inspectorTable.getModel.getRows;
                  numRows = rows.size;
                  for rowIdx = 0 : numRows-1
                      thisRow = rows.get(rowIdx);
                      propNames = setdiff(propNames, char(thisRow.getDisplayName));
                      for childIdx = 0 : thisRow.getChildrenCount-1
                          propNames = setdiff(propNames, char(thisRow.getChildAt(childIdx).getDisplayName));
                      end
                  end
              end

              % Sort properties alphabetically
              % Note: sorting is already a side-effect of setdiff, but setdiff is not called when showInspectedPropsFlag=1
              if iscell(propNames)
                  propNames = sort(propNames);
              end

              % Strip callback properties
              if ischar(propNames),  propNames = {propNames};  end
              propNames(~cellfun(@isempty,regexp(propNames,'(Fcn|Callback)$'))') = [];

              % Add property Type & Value data
              for idx = 1 : length(propNames)
                  propName = propNames{idx};
                  try
                      sp = findprop(handle(obj),propName);  %=obj.classhandle.findprop(propName);
                      prefix = '';
                      if strcmp(sp.AccessFlags.PublicSet,'off')
                          prefix = '<html><font color="#C0C0C0"><i>';
                      end
                      propsData{idx,1} = [prefix propName];
                      propsData{idx,2} = '';
                      if ~isempty(sp)
                          propsData{idx,2} = [prefix sp.DataType];
                          propsData{idx,4} = [prefix sp.AccessFlags.PublicGet];
                          propsData{idx,5} = [prefix sp.AccessFlags.PublicSet];
                          propsData{idx,6} = [prefix sp.Visible];
                          if ~strcmp(propName,'FactoryValue')
                              propsData{idx,7} = [prefix charizeData(get(sp,'FactoryValue'))];  % sp.FactoryValue fails...
                          else
                              propsData{idx,7} = '';  % otherwise Matlab crashes...
                          end
                          %propsData{idx,8} = [prefix sp.Description];
                      end
                      % TODO: some fields (see EOL comment below) generate a Java Exception from: com.mathworks.mlwidgets.inspector.PropertyRootNode$PropertyListener$1$1.run
                      if strcmp(sp.AccessFlags.PublicGet,'on') % && ~any(strcmp(sp.Name,{'FixedColors','ListboxTop','Extent'}))
                          try
                              % Trap warning about unused/depracated properties
                              s = warning('off','all');
                              lastwarn('');
                              value = get(obj, sp.Name);
                              disp(lastwarn);
                              warning(s);
                              propsData{idx,3} = charizeData(value);
                          catch
                              propsData{idx,3} = lasterr;
                              propsData{idx,1} = strrep(propsData{idx,1},propName,['<html><font color="red"><i>' propName]);
                          end
                      else
                          propsData{idx,3} = '(no public getter method)';
                      end
                      %disp({idx,propName})  % for debugging...
                  catch
                      propsData{idx,1} = propName;
                      [propsData{idx,2:7}] = deal('???');
                      propsData{idx,3} = get(obj,propName);
                  end
              end
              propTableEnabled = true;
          end
          if ~showMetaData
              % only show the Name & Value columns
              propsData = propsData(:,[1,3]);
              propsHeaders = propsHeaders(:,[1,3]);
          end
      catch
          disp(lasterr);  rethrow(lasterror)
      end
%end  % getPropsData

%% Convert property data into a string
function data = charizeData(data)
      if ~ischar(data)
          newData = strtrim(evalc('disp(data)'));
          try
              newData = regexprep(newData,'  +',' ');
              newData = regexprep(newData,'Columns \d+ through \d+\s','');
              newData = regexprep(newData,'Column \d+\s','');
          catch
              %never mind...
          end
          if iscell(data)
              newData = ['{ ' newData ' }'];
          elseif isempty(data)
              newData = '';
          elseif isnumeric(data) || islogical(data) || any(ishandle(data)) || numel(data) > 1 %&& ~isscalar(data)
              newData = ['[' newData ']'];
          end
          data = newData;
      elseif ~isempty(data)
          data = ['''' data ''''];
      end
%end  % charizeData

%% Prepare the callbacks pane
function [callbacksPanel, callbacksTable] = getCbsPane(obj, stripStdCbsFlag)
      % Prepare the callbacks pane
      import java.awt.* javax.swing.*
      callbacksPanel = JPanel(BorderLayout);
      [cbData, cbHeaders, cbTableEnabled] = getCbsData(obj, stripStdCbsFlag);
      try
          % Use JideTable if available on this system
          %callbacksTableModel = javax.swing.table.DefaultTableModel(cbData,cbHeaders);  %#ok
          %callbacksTable = eval('com.jidesoft.grid.PropertyTable(callbacksTableModel);');  % prevent JIDE alert by run-time (not load-time) evaluation
          callbacksTable = eval('com.jidesoft.grid.TreeTable(cbData,cbHeaders);');  % prevent JIDE alert by run-time (not load-time) evaluation
          callbacksTable.setRowAutoResizes(true);
          callbacksTable.setColumnAutoResizable(true);
          callbacksTable.setColumnResizable(true);
          jideTableUtils = eval('com.jidesoft.grid.TableUtils;');  % prevent JIDE alert by run-time (not load-time) evaluation
          jideTableUtils.autoResizeAllColumns(callbacksTable);
          callbacksTable.setTableHeader([]);  % hide the column headers since now we can resize columns with the gridline
          callbacksLabel = JLabel(' Callbacks:');  % The column headers are replaced with a header label
          callbacksLabel.setForeground(Color.blue);
          %callbacksPanel.add(callbacksLabel, BorderLayout.NORTH);

          % Add checkbox to show/hide standard callbacks (only if not a HG handle)
          callbacksTopPanel = JPanel;
          callbacksTopPanel.setLayout(BoxLayout(callbacksTopPanel, BoxLayout.LINE_AXIS));
          callbacksTopPanel.add(callbacksLabel);
          hgHandleFlag = 0;  try  hgHandleFlag = ishghandle(obj);  catch,  end  %#ok
          if ~hgHandleFlag && ~iscom(obj)
              callbacksTopPanel.add(Box.createHorizontalGlue);
              jcb = JCheckBox('Hide standard callbacks', stripStdCbsFlag);
              set(jcb, 'ActionPerformedCallback',@cbHideStdCbs_Callback, 'userdata',callbacksTable, 'tooltip','Hide standard Swing callbacks - only component-specific callbacks will be displayed');
              callbacksTopPanel.add(jcb);
          end
          callbacksPanel.add(callbacksTopPanel, BorderLayout.NORTH);
      catch
          % Otherwise, use a standard Swing JTable (keep the headers to enable resizing)
          callbacksTable = JTable(cbData,cbHeaders);
      end
      set(callbacksTable, 'userdata',obj);
      if iscom(obj)
          cbToolTipText = '<html>&nbsp;Callbacks may be ''string'' or @funcHandle';
      else
          cbToolTipText = '<html>&nbsp;Callbacks may be ''string'', @funcHandle or {@funcHandle,arg1,...}';
      end
      %cbToolTipText = [cbToolTipText '<br>&nbsp;{Cell} callbacks are displayed as: [Ljava.lang...'];
      callbacksTable.setToolTipText(cbToolTipText);
      %callbacksTable.setGridColor(inspectorTable.getGridColor);
      cbNameTextField = JTextField;
      cbNameTextField.setEditable(false);  % ensure that the callback names are not modified...
      cbNameCellEditor = DefaultCellEditor(cbNameTextField);
      cbNameCellEditor.setClickCountToStart(intmax);  % i.e, never enter edit mode...
      callbacksTable.getColumnModel.getColumn(0).setCellEditor(cbNameCellEditor);
      if ~cbTableEnabled && callbacksTable.getColumnModel.getColumnCount>1
          callbacksTable.getColumnModel.getColumn(1).setCellEditor(cbNameCellEditor);
      end
      set(callbacksTable.getModel, 'TableChangedCallback',@tbCallbacksChanged, 'UserData',obj);
      cbScrollPane = JScrollPane(callbacksTable);
      cbScrollPane.setVerticalScrollBarPolicy(cbScrollPane.VERTICAL_SCROLLBAR_AS_NEEDED);
      callbacksPanel.add(cbScrollPane, BorderLayout.CENTER);
      callbacksPanel.setToolTipText(cbToolTipText);
%end  % getCbsPane

%% Prepare the methods pane
function methodsPane = getMethodsPane(methodsObj, obj)
      import java.awt.* javax.swing.*
      methodsPane = JPanel(BorderLayout);

      % Get superclass if possible
      superclass = '';
      scSep = '';
      try
          if isjava(obj)
              superclass = char(obj.getClass.getSuperclass.getCanonicalName);
          end
      catch
          % never mind...
      end
      if ~isempty(superclass)
          superclass = [' (superclass: ' superclass ')'];
          scSep = '<br>&nbsp;';
      end

      % Add a label
      labelStr = ['  Methods of class ' builtin('class',obj)];
      methodsLabel = JLabel([labelStr superclass]);
      methodsLabel.setToolTipText(['<html>&nbsp;' labelStr '&nbsp;' scSep superclass]);
      methodsLabel.setForeground(Color.blue);
      methodsPane.add(methodsLabel, BorderLayout.NORTH);

      % Method A: taken from Matlab's methodsview function (slightly modified)
      %{
      ncols = length(methodsObj.widths);
      b = com.mathworks.mwt.MWListbox;
      b.setColumnCount(ncols);
      wb = 0;
      for i=1:ncols,
          wc = 7.5 * methodsObj.widths(i);
          b.setColumnWidth(i-1, wc);
          b.setColumnHeaderData(i-1, methodsObj.headers{i});
          wb = wb+wc;
      end;

      co = b.getColumnOptions;
      set(co, 'HeaderVisible', 'on');
      set(co, 'Resizable', 'on');
      b.setColumnOptions(co);
      set(b.getHScrollbarOptions,'Visibility','Always');  %Yair: fix HScrollbar bug

      ds = javaArray('java.lang.String', ncols);
      for i=1:size(methodsObj.methods,1)
          for j=1:ncols
              ds(j) = java.lang.String(methodsObj.methods{methodsObj.sortIdx(i),j});
          end;
          b.addItem(ds);
      end;
      %}

      % Method B: use a JTable - looks & refreshes much better...
      try
          com.mathworks.mwswing.MJUtilities.initJIDE;
          b = eval('com.jidesoft.grid.TreeTable(methodsObj.methods(methodsObj.sortIdx,:), methodsObj.headers);');  % prevent JIDE alert by run-time (not load-time) evaluation
          b.setRowAutoResizes(true);
          b.setColumnAutoResizable(true);
          b.setColumnResizable(true);
          jideTableUtils = eval('com.jidesoft.grid.TableUtils;');  % prevent JIDE alert by run-time (not load-time) evaluation
          jideTableUtils.autoResizeAllColumns(b);
      catch
          b = JTable(methodsObj.methods(methodsObj.sortIdx,:), methodsObj.headers);
      end

      % Hide the column header if only one column is shown
      if length(methodsObj.headers) < 2
          b.setTableHeader([]);  % hide the column headers since now we can resize columns with the gridline
      end

      b.setShowGrid(0);
      scroll = JScrollPane(b);
      scroll.setVerticalScrollBarPolicy(scroll.VERTICAL_SCROLLBAR_AS_NEEDED);
      scroll.setHorizontalScrollBarPolicy(scroll.HORIZONTAL_SCROLLBAR_AS_NEEDED);
      b.setSelectionMode(javax.swing.ListSelectionModel.SINGLE_INTERVAL_SELECTION);
      b.setAutoResizeMode(b.AUTO_RESIZE_SUBSEQUENT_COLUMNS)
      %b.setEnabled(0);
      cbNameTextField = JTextField;
      cbNameTextField.setEditable(false);  % ensure that the callback names are not modified...
      cbNameCellEditor = DefaultCellEditor(cbNameTextField);
      cbNameCellEditor.setClickCountToStart(intmax);  % i.e, never enter edit mode...
      for colIdx = 1:length(methodsObj.headers)
          b.getColumnModel.getColumn(colIdx-1).setCellEditor(cbNameCellEditor);
      end

      % Attach the listbox to the methods panel
      methodsPane.add(scroll, BorderLayout.CENTER);
%end  % getMethodsPane

%% Prepare the children pane (Display additional props that are not inspectable by the inspector)
function othersPane = getChildrenPane(obj, inspectorTable)
      import java.awt.* javax.swing.*

      % Label
      othersLabel = JLabel(' Other properties');
      othersLabel.setForeground(Color.blue);
      othersLabel.setToolTipText('Properties not inspectable by the inspect table above');
      ud.othersLabel = othersLabel;
      othersPane = JPanel(BorderLayout);
      %othersPane.add(othersLabel, BorderLayout.NORTH);

      % Data table
      [propsData, propsHeaders] = getPropsData(obj, false, false, inspectorTable);
      try
          % Use JideTable if available on this system
          %propsTableModel = javax.swing.table.DefaultTableModel(cbData,cbHeaders);  %#ok
          %propsTable = eval('com.jidesoft.grid.PropertyTable(propsTableModel);');  % prevent JIDE alert by run-time (not load-time) evaluation
          propsTable = eval('com.jidesoft.grid.TreeTable(propsData,propsHeaders);');  % prevent JIDE alert by run-time (not load-time) evaluation
          propsTable.setRowAutoResizes(true);
          propsTable.setColumnAutoResizable(true);
          propsTable.setColumnResizable(true);
          jideTableUtils = eval('com.jidesoft.grid.TableUtils;');  % prevent JIDE alert by run-time (not load-time) evaluation
          jideTableUtils.autoResizeAllColumns(propsTable);
          %propsTable.setTableHeader([]);  % hide the column headers since now we can resize columns with the gridline
      catch
          % Otherwise, use a standard Swing JTable (keep the headers to enable resizing)
          propsTable = JTable(propsData,propsHeaders);
      end
      %propsToolTipText = '<html>&nbsp;Callbacks may be ''strings'' or {@myFunc,arg1,...}';
      %propsTable.setToolTipText(propsToolTipText);
      %propsTable.setGridColor(inspectorTable.getGridColor);
      propNameTextField = JTextField;
      propNameTextField.setEditable(false);  % ensure that the prop names are not modified...
      propNameCellEditor = DefaultCellEditor(propNameTextField);
      propNameCellEditor.setClickCountToStart(intmax);  % i.e, never enter edit mode...
      propsTable.getColumnModel.getColumn(0).setCellEditor(propNameCellEditor);
      ud.obj = obj;
      ud.inspectorTable = inspectorTable;
      set(propsTable.getModel, 'TableChangedCallback',@tbPropChanged, 'UserData',ud);
      scrollPane = JScrollPane(propsTable);
      scrollPane.setVerticalScrollBarPolicy(scrollPane.VERTICAL_SCROLLBAR_AS_NEEDED);
      othersPane.add(scrollPane, BorderLayout.CENTER);

      % Add checkbox to show/hide meta-data & inspectable properties
      othersTopPanel = JPanel;
      othersTopPanel.setLayout(BoxLayout(othersTopPanel, BoxLayout.LINE_AXIS));
      othersTopPanel.add(othersLabel);
      othersTopPanel.add(Box.createHorizontalGlue);
      jcb = JCheckBox('Meta-data', 0);
      set(jcb, 'ActionPerformedCallback',@updatePropsTable, 'userdata',propsTable, 'tooltip','Also show property meta-data (type, visibility, get/set availability, etc.)');
      ud.cbMetaData = jcb;
      othersTopPanel.add(jcb);
      jcb = JCheckBox('Inspectable', 0);
      set(jcb, 'ActionPerformedCallback',@updatePropsTable, 'userdata',propsTable, 'tooltip','Also show inspectable properties (displayed in the table above)');
      ud.cbInspected = jcb;
      othersTopPanel.add(jcb);
      othersPane.add(othersTopPanel, BorderLayout.NORTH);

      % Preserve persistent info in the propsTable's userdata
      set(propsTable, 'userdata',ud);
%end  % getChildrenPane

%% "dbstop if error" causes inspect.m to croak due to a bug - so workaround by temporarily disabling this dbstop
function identifiers = disableDbstopError
    dbStat = dbstatus;
    idx = find(strcmp({dbStat.cond},'error'));
    identifiers = [dbStat(idx).identifier];
    if ~isempty(idx)
        dbclear if error;
        msgbox('''dbstop if error'' had to be disabled due to a Matlab bug that would have caused Matlab to crash.', 'FindJObj', 'warn');
    end
%end  % disableDbstopError

%% Restore any previous "dbstop if error"
function restoreDbstopError(identifiers)  %#ok unused
    for itemIdx = 1 : length(identifiers)
        eval(['dbstop if error ' identifiers{itemIdx}]);
    end
%end  % restoreDbstopError

%% Strip standard Swing callbacks from a list of events
function evNames = stripStdCbs(evNames)
    try
        stdEvents = {'AncestorAdded', 'AncestorMoved', 'AncestorRemoved', 'AncestorResized', ...
                     'CaretPositionChanged', 'ComponentAdded', 'ComponentRemoved', ...
                     'ComponentHidden', 'ComponentMoved', 'ComponentResized', 'ComponentShown', ...
                     'PropertyChange', 'FocusGained', 'FocusLost', ...
                     'HierarchyChanged', 'InputMethodTextChanged', ...
                     'KeyPressed', 'KeyReleased', 'KeyTyped', ...
                     'MouseClicked', 'MouseDragged', 'MouseEntered', 'MouseExited', ...
                     'MouseMoved', 'MousePressed', 'MouseReleased', 'MouseWheelMoved', ...
                     'VetoableChange'};
        evNames = setdiff(evNames,strcat(stdEvents,'Callback'))';
    catch
        % Never mind...
        disp(lasterr);  rethrow(lasterror)
    end
%end  % stripStdCbs

%% Callback function for <Hide standard callbacks> checkbox
function cbHideStdCbs_Callback(src, evd, varargin)
    try
        % Update callbacks table data according to the modified checkbox state
        callbacksTable = get(src,'userdata');
        obj = get(callbacksTable, 'userdata');
        [cbData, cbHeaders] = getCbsData(obj, evd.getSource.isSelected);
        callbacksTableModel = javax.swing.table.DefaultTableModel(cbData,cbHeaders);
        set(callbacksTableModel, 'TableChangedCallback',@tbCallbacksChanged, 'UserData',handle(obj,'CallbackProperties'));
        callbacksTable.setModel(callbacksTableModel)
        try
            % Try to auto-resize the columns
            callbacksTable.setRowAutoResizes(true);
            jideTableUtils = eval('com.jidesoft.grid.TableUtils;');  % prevent JIDE alert by run-time (not load-time) evaluation
            jideTableUtils.autoResizeAllColumns(callbacksTable);
        catch
            % JIDE is probably unavailable - never mind...
        end
    catch
        % Never mind...
        %disp(lasterr);  rethrow(lasterror)
    end
%end  % cbHideStdCbs_Callback

%% Update the properties table following a checkbox modification
function updatePropsTable(src, evd, varargin)  %#ok partially unused
    try
        % Update callbacks table data according to the modified checkbox state
        propsTable = get(src,'userdata');
        ud = get(propsTable, 'userdata');
        obj = ud.obj;
        inspectorTable = ud.inspectorTable;
        [propData, propHeaders] = getPropsData(obj, ud.cbMetaData.isSelected, ud.cbInspected.isSelected, inspectorTable);
        propsTableModel = javax.swing.table.DefaultTableModel(propData,propHeaders);
        try
            ud.obj = handle(obj,'CallbackProperties');
        catch
            ud.obj = handle(obj);
        end
        ud.inspectorTable = inspectorTable;
        set(propsTableModel, 'TableChangedCallback',@tbPropChanged, 'UserData',ud);
        propsTable.setModel(propsTableModel)
        try
            % Try to auto-resize the columns
            propsTable.setRowAutoResizes(true);
            jideTableUtils = eval('com.jidesoft.grid.TableUtils;');  % prevent JIDE alert by run-time (not load-time) evaluation
            jideTableUtils.autoResizeAllColumns(propsTable);
        catch
            % JIDE is probably unavailable - never mind...
        end

        % Update the header label
        if ud.cbInspected.isSelected
            set(ud.othersLabel,'Text',' All properties', 'ToolTipText','All properties (including those shown above)');
        else
            set(ud.othersLabel,'Text',' Other properties', 'ToolTipText','Properties not inspectable by the inspect table above');
        end

        % Disable editing all columns except the property Value
        import javax.swing.*
        propTextField = JTextField;
        propTextField.setEditable(false);  % ensure that the prop names & meta-data are not modified...
        propCellEditor = DefaultCellEditor(propTextField);
        propCellEditor.setClickCountToStart(intmax);  % i.e, never enter edit mode...
        for colIdx = 0 : propsTable.getColumnModel.getColumnCount-1
            thisColumn = propsTable.getColumnModel.getColumn(colIdx);
            if ~strcmp(thisColumn.getHeaderValue,'Value')
                thisColumn.setCellEditor(propCellEditor);
            end
        end
    catch
        % Never mind...
        disp(lasterr);  rethrow(lasterror)
    end
%end  % updatePropsTable

%% Update component callback upon callbacksTable data change
function tbCallbacksChanged(src, evd)
    try
        % exit if invalid handle or already in Callback
        if ~ishandle(src) || ~isempty(getappdata(src,'inCallback')) % || length(dbstack)>1  %exit also if not called from user action
            return;
        end
        setappdata(src,'inCallback',1);  % used to prevent endless recursion

        % Update the object's callback with the modified value
        modifiedColIdx = evd.getColumn;
        modifiedRowIdx = evd.getFirstRow;
        if modifiedColIdx==1 && modifiedRowIdx>=0  %sanity check - should always be true
            table = evd.getSource;
            object = get(src,'userdata');
            cbName = strtrim(table.getValueAt(modifiedRowIdx,0));
            try
                cbValue = strtrim(char(table.getValueAt(modifiedRowIdx,1)));
                if ~isempty(cbValue) && ismember(cbValue(1),'{[@''')
                    cbValue = eval(cbValue);
                end
                if (~ischar(cbValue) && ~isa(cbValue, 'function_handle') && (iscom(object(1)) || iscell(cbValue)))
                    revertCbTableModification(table, modifiedRowIdx, modifiedColIdx, cbName, object, '');
                else
                    for objIdx = 1 : length(object)
                        if ~iscom(object(objIdx))
                            set(object(objIdx), cbName, cbValue);
                        else
                            cbs = object(objIdx).eventlisteners;
                            if ~isempty(cbs)
                                cbs = cbs(strcmpi(cbs(:,1),cbName),:);
                                object(objIdx).unregisterevent(cbs);
                            end
                            if ~isempty(cbValue)
                                object(objIdx).registerevent({cbName, cbValue});
                            end
                        end
                    end
                end
            catch
                revertCbTableModification(table, modifiedRowIdx, modifiedColIdx, cbName, object, lasterr)
            end
        end
    catch
        % never mind...
    end
    setappdata(src,'inCallback',[]);  % used to prevent endless recursion
%end  % tbCallbacksChanged

%% Revert Callback table modification
function revertCbTableModification(table, modifiedRowIdx, modifiedColIdx, cbName, object, errMsg)  %#ok
    try
        % Display a notification MsgBox
        msg = 'Callbacks must be a ''string'', or a @function handle';
        if ~iscom(object(1)),  msg = [msg ' or a {@func,args...} construct'];  end
        if ~isempty(errMsg),  msg = {errMsg, '', msg};  end
        msgbox(msg, ['Error setting ' cbName ' callback'], 'warn');

        % Revert to the current value
        curValue = '';
        try
            if ~iscom(object(1))
                curValue = charizeData(get(object(1),cbName));
            else
                cbs = object(1).eventlisteners;
                if ~isempty(cbs)
                    cbs = cbs(strcmpi(cbs(:,1),cbName),:);
                    curValue = charizeData(cbs(1,2));
                end
            end
        catch
            % never mind... - clear the current value
        end
        table.setValueAt(curValue, modifiedRowIdx, modifiedColIdx);
    catch
        % never mind...
    end
%end  % revertCbTableModification

%% Update component property upon properties table data change
function tbPropChanged(src, evd)
    % exit if invalid handle
    if ~ishandle(src)  % || length(dbstack)>1  %exit also if not called from user action
        return;
    end

    % Update the object's property with the modified value
    modifiedColIdx = evd.getColumn;
    modifiedRowIdx = evd.getFirstRow;
    if modifiedRowIdx>=0  %sanity check - should always be true
        table = evd.getSource;
        ud = get(src,'userdata');
        object = ud.obj;
        inspectorTable = ud.inspectorTable;
        propName = strtrim(table.getValueAt(modifiedRowIdx,0));
        propName = strrep(propName,'<html><font color="#C0C0C0"><i>','');
        propName = strrep(propName,'<html><font color="red"><i>','');
        try
            propValue = strtrim(table.getValueAt(modifiedRowIdx,modifiedColIdx));
            if ~isempty(propValue) && ismember(propValue(1),'{[@''')
                propValue = eval(propValue);
            end
            for objIdx = 1 : length(object)
                set(object(objIdx), propName, propValue);
            end
        catch
            msg = {lasterr, '', ...
                   'Values are interpreted as strings except if enclosed by square brackets [] or curly braces {}', ...
                   '', 'Even simple boolean/numeric values need to be enclosed within [] brackets', ...
                   'For example: [0] or: [pi]'};
            msgbox(msg,['Error setting ' propName ' property'],'error');
            try
                % Revert to the current value (temporarily disable this callback to prevent recursion)
                curValue = charizeData(get(object(1),propName));
                set(table, 'TableChangedCallback',[]);
                table.setValueAt(curValue, modifiedRowIdx, modifiedColIdx);
                set(table, 'TableChangedCallback',@tbPropChanged);
            catch
                % never mind...
            end
        end
        %pause(0.2); awtinvoke(inspectorTable,'repaint(J)',2000);  % not good enough...
        start(timer('TimerFcn',{@repaintInspector,inspectorTable},'StartDelay',2));
    end
%end  % tbPropChanged

%% Repaint inspectorTable following a property modification
function repaintInspector(timerObj, timerData, inspectorTable)  %#ok partially unused
    inspectorTable.repaint;
%end % repaintInspector

%% Get an HTML representation of the object's properties
function dataFieldsStr = getPropsHtml(obj, dataFields)
    try
        % Get a text representation of the fieldnames & values
        undefinedStr = '';
        dataFieldsStr = '';  % just in case the following croaks...
        if isempty(dataFields)
            return;
        end
        dataFieldsStr = evalc('disp(dataFields)');
        if dataFieldsStr(end)==char(10),  dataFieldsStr=dataFieldsStr(1:end-1);  end

        % Strip out callbacks
        dataFieldsStr = regexprep(dataFieldsStr,'^\s*\w*Callback(Data)?:[^\n]*$','','lineanchors');
        dataFieldsStr = regexprep(dataFieldsStr,'\n\n','\n');

        % HTMLize tooltip data
        % First, set the fields' font based on its read-write status
        try
            % ensure this is a Matlab handle, not a java object
            obj = handle(obj, 'CallbackProperties');
        catch
            % HG handles don't allow CallbackProperties...
            obj = handle(obj);
        end
        fieldNames = fieldnames(dataFields);
        for fieldIdx = 1 : length(fieldNames)
            thisFieldName = fieldNames{fieldIdx};
            accessFlags = get(findprop(obj,thisFieldName),'AccessFlags');
            if isfield(accessFlags,'PublicSet') && strcmp(accessFlags.PublicSet,'on')
                % Bolden read/write fields
                thisFieldFormat = ['<b>' thisFieldName '<b>:$2'];
            elseif ~isfield(accessFlags,'PublicSet')
                % Undefined - probably a Matlab-defined field of com.mathworks.hg.peer.FigureFrameProxy...
                thisFieldFormat = ['<font color="blue">' thisFieldName '</font>:$2'];
                undefinedStr = ', <font color="blue">undefined</font>';
            else % PublicSet=='off'
                % Gray-out & italicize any read-only fields
                thisFieldFormat = ['<font color="#C0C0C0"><i>' thisFieldName '</i></font>:<font color="#C0C0C0"><i>$2<i></font>'];
            end
            dataFieldsStr = regexprep(dataFieldsStr, ['([\s\n])' thisFieldName ':([^\n]*)'], ['$1' thisFieldFormat]);
        end
    catch
        % never mind... - probably an ambiguous property name
        disp(lasterr);  rethrow(lasterror)
    end

    try
        % Method 1: simple <br> list
        %dataFieldsStr = strrep(dataFieldsStr,char(10),'&nbsp;<br>&nbsp;&nbsp;');

        % Method 2: 2x2-column <table>
        dataFieldsStr = regexprep(dataFieldsStr, '^\s*([^:]+:)([^\n]*)\n^\s*([^:]+:)([^\n]*)$', '<tr><td>&nbsp;$1</td><td>&nbsp;$2</td><td>&nbsp;&nbsp;&nbsp;&nbsp;$3</td><td>&nbsp;$4&nbsp;</td></tr>', 'lineanchors');
        dataFieldsStr = regexprep(dataFieldsStr, '^[^<]\s*([^:]+:)([^\n]*)$', '<tr><td>&nbsp;$1</td><td>&nbsp;$2</td><td>&nbsp;</td><td>&nbsp;</td></tr>', 'lineanchors');
        dataFieldsStr = ['(<b>modifiable</b>' undefinedStr ' &amp; <font color="#C0C0C0"><i>read-only</i></font> fields)<p>&nbsp;&nbsp;<table cellpadding="0" cellspacing="0">' dataFieldsStr '</table>'];
    catch
        % never mind - bail out (Maybe matlab 6 that does not support regexprep?)
        disp(lasterr);  rethrow(lasterror)
    end
%end  % getPropsHtml

%% Update tooltip string with an object's properties data
function dataFields = updateObjTooltip(obj, uiObject)
    try
        toolTipStr = builtin('class',obj);
        dataFields = struct;  % empty struct
        dataFieldsStr = '';
        hgStr = '';

        % Add HG annotation if relevant
        if ishghandle(obj)
            hgStr = ' HG Handle';
        end

        % Note: don't bulk-get because (1) not all properties are returned & (2) some properties cause a Java exception
        % Note2: the classhandle approach does not enable access to user-defined schema.props
        ch = classhandle(obj);
        dataFields = [];
        [sortedNames, sortedIdx] = sort(get(ch.Properties,'Name'));
        for idx = 1 : length(sortedIdx)
            sp = ch.Properties(sortedIdx(idx));
            % TODO: some fields (see EOL comment below) generate a Java Exception from: com.mathworks.mlwidgets.inspector.PropertyRootNode$PropertyListener$1$1.run
            if strcmp(sp.AccessFlags.PublicGet,'on') % && ~any(strcmp(sp.Name,{'FixedColors','ListboxTop','Extent'}))
                dataFields.(sp.Name) = get(obj, sp.Name);
            else
                dataFields.(sp.Name) = '(no public getter method)';
            end
        end
        dataFieldsStr = getPropsHtml(obj, dataFields);
    catch
        % Probably a non-HG java object
        try
            % Note: the bulk-get approach enables access to user-defined schema-props, but not to some original classhandle Properties...
            dataFields = get(obj);
            dataFieldsStr = getPropsHtml(obj, dataFields);
        catch
            % Probably a missing property getter implementation
            try
                % Inform the user - bail out on error
                err = lasterror;
                dataFieldsStr = ['<p>' strrep(err.message, char(10), '<br>')];
            catch
                % forget it...
            end
        end
    end

    % Set the object tooltip
    if ~isempty(dataFieldsStr)
        toolTipStr = ['<html>&nbsp;<b><u><font color="red">' char(toolTipStr) '</font></u></b>' hgStr ':&nbsp;' dataFieldsStr '</html>'];
    end
    uiObject.setToolTipText(toolTipStr);
%end  % updateObjTooltip



%%%%%%%%%%%%%%%%%%%%%%%%%% TODO %%%%%%%%%%%%%%%%%%%%%%%%%
% - Enh: Cleanup internal functions, remove duplicates etc.
% - Enh: link objects to another uiinspect window for these objects
% - Enh: display object children (& link to them)
% - Enh: find a way to merge the other-properties table into the inspector table
% - Fix: some fields generate a Java Exception from: com.mathworks.mlwidgets.inspector.PropertyRootNode$PropertyListener$1$1.run

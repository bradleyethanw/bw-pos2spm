function varargout = pos_parameters(varargin)
%% Information

% Name:         POS Parameters GUI
% Files:        (pos_parameters.fig and pos_parameters.m)

% Author:       Bradley E. White (Bradley.White@gallaudet.edu)

% Date:         4 January 2016
% Last Update:  5 January 2016

% MATLAB:       R2012b

% Use(s): This GUI gathers all of the parameters for the POS file
% conversion, namely the participant ID, the number of POS files, the probe
% array, and the file format(s) to output.  Why a GUI?  This is a lot
% cleaner when executing parameter-based functions in the actual POS2SPM
% conversion script.  This was also thought to be more user friendly, as
% all parameters could be seen in one window, versus a number of different
% windows.  However, you can substitute other MATLAB menu/input dialogues
% (recoding the POS2SPM script to match) or manual input of the variables
% (coded appropriately for each parameter; i.e., "num_pos = 2" to indicate
% that you are using only one POS file).

%% License Agreement

% POS2SPM CONVERSION TOOL
% Copyright (C) 2016 Bradley E. White

% This program is free software: you can redistribute it and/or modify it 
% under the terms of the GNU General Public License as published by the 
% Free Software Foundation, either version 3 of the License, or (at your 
% option) any later version.

% This program is distributed in the hope that it will be useful, but 
% WITHOUT ANY WARRANTY; without even the implied warranty of 
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
% Public License for more details.

% You should have received a copy of the GNU General Public License along 
% with this program.  If not, see <http://www.gnu.org/licenses/gpl>.

% POS2SPM is classified as ?Individual Efforts? under the Gallaudet 
% University Administration and Operations Manual § 1.09.II.A.5, see 
% <http://www.gallaudet.edu/af/aando-manual.html>.

%% Begin initialization code - do not edit - from GUIDE
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @pos_parameters_OpeningFcn, ...
                   'gui_OutputFcn',  @pos_parameters_OutputFcn, ...
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
% End initialization code - do not edit - from GUIDE

% Executes just before the GUI is visible, no output arguments, establishes
% handle outputs
function pos_parameters_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
% Update handle structures
guidata(hObject, handles);
% Reposition the GUI
movegui('center')

% Variable outputs from GUI
function varargout = pos_parameters_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

% Pushbutton to proceed with POS conversion using all selected parameters
function pushbutton1_Callback(hObject, eventdata, handles)
close pos_parameters

% Participant ID - changes with entry and adds to workspace
function ParticipantID_Callback(hObject, eventdata, handles)
ParticipantID = get(hObject,'String')
assignin('base', 'ParticipantID', ParticipantID);

function ParticipantID_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% File output format(s) - changes with selection and adds to workspace
function file_output_Callback(hObject, eventdata, handles)
file_output = get(hObject, 'Value')
assignin('base', 'file_output', file_output);

function file_output_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% Probe array - changes with selection and adds to workspace
function probe_array_Callback(hObject, eventdata, handles)
probe_array = get(hObject, 'Value')
assignin('base', 'probe_array', probe_array);

function probe_array_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% Number of POS files - changes with selection and adds to workspace
function num_pos_Callback(hObject, eventdata, handles)
num_pos = get(hObject, 'Value')
assignin('base', 'num_pos', num_pos);

function num_pos_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

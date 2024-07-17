%% Information

% Name:         POS-2-SPM (pos2spm.m)
% Author:       Bradley E. White (Bradley.White@gallaudet.edu)

% Date:         3 December 2015
% Last update:  1 February 2016

% MATLAB:       R2012b

% Input(s):     ###.pos (x1 or x2)

% Output(s):    ParticipantID_origins.csv
%               ParticipantID_others.csv
%               reference_positions.csv
%               optode_positions.csv
%               ch_config.csv
%               ch_config.txt

% Use(s):  This script was designed to generate the appropriately formatted
% files necessary to process spatial (i.e., 3D digitization) information
% with the NIRS-SPM (SPM5 or SPM8) and/or the SPM-fNIRS toolbox (SPM12)
% from one or two POS measurement files from an electromagnetic 3D
% digitizer, such as Polhemus (Polhemus, Colchester, VT).

% Compatibility:  The purpose of this script is to provide a conversion and
% formatting tool that can be applied to a number of different probe arrays
% with either one or two POS measurement files.  The probe arrays and
% configurations currently compatible with the POS-2-SPM package can be
% found in the documentation or within the channel configuration folder.

% Function(s):  This script will generate the estimated channel coordinates
% based on an average of the source and detector coordinates that compose
% that channel.  The source-detector-channel relationship is based on the
% channel configuration of the probe array with which you are working.  For
% multiple POS measurement files, an average of the two measurement
% sessions will be outputted.  Appropriately formatted output files for the
% NIRS-SPM toolbox, SPM-fNIRS toolbox, or both will be generated based on
% the parameters set by the user.  All output files are packaged in a
% folder labeled "Polhemus" precisely one directory level up from where the
% POS measurement files were selected.

% Disclaimer:  The POS-2-SPM software package was made possible by the
% pos2csv and ReadPos functions created by and available from the
% Functional Brain Science Laboratory at the Center for Development of
% Advanced Medical Technology, Jichi Medical University (1,2,3).  Portions
% of these functions were modified and/or adapted to be used in conjunction
% with a number of proprietary scripts and files written by the author.

% References:

% 1. Singh, A. K., Okamoto, M., Dan, H., Jurcak, V., & Dan, I. (2005). 
% Spatial registration of multichannel multi-subject fNIRS data to MNI 
% space without MRI. Neuroimage, 27(4), 842-851.

% 2. NFRI Toolbox. Functional Brain Science Laboratory, Center for 
% Development of Advanced Medical Technology, Jichi Medical University. 
% http://www.jichi.ac.jp/brainlab/tools.html#GroupSp/.

% 3. NFRI Toolbox User's Guide. Functional Brain Science Laboratory, Center
% for Development of Advanced Medical Technology, Jichi Medical University. 
% http://jichi.ac.jp/brainlab/download/ReadMe091114.doc.

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

%% Begin script

%% Blank slate
clear all

%% Set parameters for POS conversion

waitfor(pos_parameters);

% Error for participant ID not entered
IDCheck1 = exist ('ParticipantID', 'var');
if IDCheck1 == 0
    error('YOU MUST ENTER A PARTICIPANT ID TO CONTINUE!')
end
clear IDCheck1

% Error for participant ID cleared
IDCheck2 = isempty (ParticipantID);
if IDCheck2 == 1
    error('YOU MUST ENTER A PARTICIPANT ID TO CONTINUE!')
end
clear IDCheck2

% Error for not selecting the number of POS files
if num_pos == 1
    error('YOU MUST SELECT THE NUMBER OF POS FILES TO CONTINUE!')
end

% Error for not selecting the probe array
if probe_array == 1
    error('YOU MUST SELECT THE PROBE ARRAY TO CONTINUE!')
end

% Error for not selecting the file output format(s)
if file_output == 1
    error('YOU MUST SELECT THE OUTPUT FORMAT(S) TO CONTINUE!')
end

%% Only one POS file
if num_pos == 2
    %% Modified pos2csv
    
    % POS fileparts
    waitfor(helpdlg({'In the next window, you will be prompted to select the .pos file.'; ''; 'Press "OK" or close to continue.'}, 'pos2spm'));
    [filename, pathname, ~] = uigetfile('*.pos', 'Select the .pos file');
    
    % Modified pos2csv
    [~, XYZ, XYZ_AER_NXYZ] = ReadPos_modified([pathname filename]);
    
    originfile = [pathname, ParticipantID, '_origin.csv'];
    othersfile = [pathname, ParticipantID, '_others.csv'];
    
    %% Generate origin file (modified pos2csv)
    fid = fopen(originfile, 'w');
    fprintf(fid, '"Label","X","Y","Z",\n'); % Header
    fprintf(fid, '"Nz",%f,%f,%f\n', XYZ(3, :)); % Nz
    fprintf(fid, '"Iz",%f,%f,%f\n', XYZ(4, :)); % Iz
    fprintf(fid, '"AR",%f,%f,%f\n', XYZ(2, :)); % AR
    fprintf(fid, '"AL",%f,%f,%f\n', XYZ(1, :)); % AL
    for k = 1:7
        fprintf(fid, ',,,,\n'); % Fp1, Fp2, Fz, F3, F4, F7, F8
    end
    fprintf(fid, '"Cz",%f,%f,%f\n', XYZ(5, :)); % Cz
    for k = 1:11
        fprintf(fid, ',,,,\n'); % C3, C4, T3, T4, Pz, P3, P4, T5, T6, O1, O2
    end
    fclose(fid);
    
    %% Generate others file (modified pos2csv)
    fid = fopen(othersfile, 'w');
    for k = 6:size(XYZ, 1)-1
        fprintf(fid, ',%f,%f,%f\n', XYZ(k, :));
    end
    fclose(fid);
    
    %% Generate channel positions and add labels for 3x3 x2 probe array
    if probe_array == 2
        
        % Generate channel positions
        CH = zeros(24,3);
        for i = 1:3
            CH(1,i) = mean([XYZ(6,i),XYZ(7,i)]);
            CH(2,i) = mean([XYZ(8,i),XYZ(7,i)]);
            CH(3,i) = mean([XYZ(6,i),XYZ(9,i)]);
            CH(4,i) = mean([XYZ(10,i),XYZ(7,i)]);
            CH(5,i) = mean([XYZ(8,i),XYZ(11,i)]);
            CH(6,i) = mean([XYZ(10,i),XYZ(9,i)]);
            CH(7,i) = mean([XYZ(10,i),XYZ(11,i)]);
            CH(8,i) = mean([XYZ(12,i),XYZ(9,i)]);
            CH(9,i) = mean([XYZ(10,i),XYZ(13,i)]);
            CH(10,i) = mean([XYZ(14,i),XYZ(11,i)]);
            CH(11,i) = mean([XYZ(12,i),XYZ(13,i)]);
            CH(12,i) = mean([XYZ(14,i),XYZ(13,i)]);
            CH(13,i) = mean([XYZ(15,i),XYZ(16,i)]);
            CH(14,i) = mean([XYZ(17,i),XYZ(16,i)]);
            CH(15,i) = mean([XYZ(15,i),XYZ(18,i)]);
            CH(16,i) = mean([XYZ(19,i),XYZ(16,i)]);
            CH(17,i) = mean([XYZ(17,i),XYZ(20,i)]);
            CH(18,i) = mean([XYZ(19,i),XYZ(18,i)]);
            CH(19,i) = mean([XYZ(19,i),XYZ(20,i)]);
            CH(20,i) = mean([XYZ(21,i),XYZ(18,i)]);
            CH(21,i) = mean([XYZ(19,i),XYZ(22,i)]);
            CH(22,i) = mean([XYZ(23,i),XYZ(20,i)]);
            CH(23,i) = mean([XYZ(21,i),XYZ(22,i)]);
            CH(24,i) = mean([XYZ(23,i),XYZ(22,i)]);
        end
        
        % Open others file to add channels and labels
        filename = othersfile;
        delimiter = ',';
        formatSpec = '%s%f%f%f%[^\n\r]';
        fileID = fopen(filename,'r');
        optodeArray = textscan(fileID, formatSpec, 'Delimiter', delimiter,  'ReturnOnError', false);
        fclose(fileID);
        
        % Format channel information
        CH=num2cell(CH);
        
        SDX=vertcat(optodeArray{:,2});
        SDY=vertcat(optodeArray{:,3});
        SDZ=vertcat(optodeArray{:,4});
        CHX=vertcat(CH{:,1});
        CHY=vertcat(CH{:,2});
        CHZ=vertcat(CH{:,3});
        
        optode_positions(:,2)=[SDX;CHX];
        optode_positions(:,3)=[SDY;CHY];
        optode_positions(:,4)=[SDZ;CHZ];
        
        optode_positions=num2cell(optode_positions);
        
        % Create optode and channel labels
        SDCH = {'S19';'D16';'S16';'D18';'S18';'D15';'S10';'D17';
            'S17';'S12';'D13';'S15';'D11';'S13';'D14';'S11';'D12';
            'S14';'CH01';'CH02';'CH03';'CH04';'CH05';'CH06';
            'CH07';'CH08';'CH09';'CH10';'CH11';'CH12';'CH13';
            'CH14';'CH15';'CH16';'CH17';'CH18';'CH19';'CH20';
            'CH21';'CH22';'CH23';'CH24'};
        
        % Add labels
        optode_positions(:,1)=SDCH;
        
        % Print channel and label info to file
        fid = fopen(othersfile, 'wt');
        for i=1:size(optode_positions,1);
            fprintf(fid, '%s,%f,%f,%f\n', optode_positions{i,:});
        end
        fclose(fid);
    end
    
    %% Generate channel positions and add labels for 3x5 x2 probe array
    if probe_array == 3
        
        % Generate channel positions
        CH = zeros(44,3);
        for i = 1:3
            CH(1,i) = mean([XYZ(6,i),XYZ(7,i)]);
            CH(2,i) = mean([XYZ(7,i),XYZ(8,i)]);
            CH(3,i) = mean([XYZ(8,i),XYZ(9,i)]);
            CH(4,i) = mean([XYZ(9,i),XYZ(10,i)]);
            CH(5,i) = mean([XYZ(6,i),XYZ(11,i)]);
            CH(6,i) = mean([XYZ(7,i),XYZ(12,i)]);
            CH(7,i) = mean([XYZ(8,i),XYZ(13,i)]);
            CH(8,i) = mean([XYZ(9,i),XYZ(14,i)]);
            CH(9,i) = mean([XYZ(10,i),XYZ(15,i)]);
            CH(10,i) = mean([XYZ(11,i),XYZ(12,i)]);
            CH(11,i) = mean([XYZ(12,i),XYZ(13,i)]);
            CH(12,i) = mean([XYZ(13,i),XYZ(14,i)]);
            CH(13,i) = mean([XYZ(14,i),XYZ(15,i)]);
            CH(14,i) = mean([XYZ(11,i),XYZ(16,i)]);
            CH(15,i) = mean([XYZ(12,i),XYZ(17,i)]);
            CH(16,i) = mean([XYZ(13,i),XYZ(18,i)]);
            CH(17,i) = mean([XYZ(14,i),XYZ(19,i)]);
            CH(18,i) = mean([XYZ(15,i),XYZ(20,i)]);
            CH(19,i) = mean([XYZ(16,i),XYZ(17,i)]);
            CH(20,i) = mean([XYZ(17,i),XYZ(18,i)]);
            CH(21,i) = mean([XYZ(18,i),XYZ(19,i)]);
            CH(22,i) = mean([XYZ(19,i),XYZ(20,i)]);
            CH(23,i) = mean([XYZ(21,i),XYZ(22,i)]);
            CH(24,i) = mean([XYZ(22,i),XYZ(23,i)]);
            CH(25,i) = mean([XYZ(23,i),XYZ(24,i)]);
            CH(26,i) = mean([XYZ(24,i),XYZ(25,i)]);
            CH(27,i) = mean([XYZ(21,i),XYZ(26,i)]);
            CH(28,i) = mean([XYZ(22,i),XYZ(27,i)]);
            CH(29,i) = mean([XYZ(23,i),XYZ(28,i)]);
            CH(30,i) = mean([XYZ(24,i),XYZ(29,i)]);
            CH(31,i) = mean([XYZ(25,i),XYZ(30,i)]);
            CH(32,i) = mean([XYZ(26,i),XYZ(27,i)]);
            CH(33,i) = mean([XYZ(27,i),XYZ(28,i)]);
            CH(34,i) = mean([XYZ(28,i),XYZ(29,i)]);
            CH(35,i) = mean([XYZ(29,i),XYZ(30,i)]);
            CH(36,i) = mean([XYZ(26,i),XYZ(31,i)]);
            CH(37,i) = mean([XYZ(27,i),XYZ(32,i)]);
            CH(38,i) = mean([XYZ(28,i),XYZ(33,i)]);
            CH(39,i) = mean([XYZ(29,i),XYZ(34,i)]);
            CH(40,i) = mean([XYZ(30,i),XYZ(35,i)]);
            CH(41,i) = mean([XYZ(31,i),XYZ(32,i)]);
            CH(42,i) = mean([XYZ(32,i),XYZ(33,i)]);
            CH(43,i) = mean([XYZ(33,i),XYZ(34,i)]);
            CH(44,i) = mean([XYZ(34,i),XYZ(35,i)]);
        end
        
        % Open others file to add channels and labels
        filename = othersfile;
        delimiter = ',';
        formatSpec = '%s%f%f%f%[^\n\r]';
        fileID = fopen(filename,'r');
        optodeArray = textscan(fileID, formatSpec, 'Delimiter', delimiter,  'ReturnOnError', false);
        fclose(fileID);
        
        % Format channel information
        CH=num2cell(CH);
        
        SDX=vertcat(optodeArray{:,2});
        SDY=vertcat(optodeArray{:,3});
        SDZ=vertcat(optodeArray{:,4});
        CHX=vertcat(CH{:,1});
        CHY=vertcat(CH{:,2});
        CHZ=vertcat(CH{:,3});
        
        optode_positions(:,2)=[SDX;CHX];
        optode_positions(:,3)=[SDY;CHY];
        optode_positions(:,4)=[SDZ;CHZ];
        
        optode_positions=num2cell(optode_positions);
        
        % Create optode and channel labels
        SDCH = {'S11';'D11';'S12';'D12';'S13';'D13';'S14';'D14';
            'S15';'D15';'S16';'D16';'S17';'D17';'S18';'S21';'D21';
            'S22';'D22';'S23';'D23';'S24';'D24';'S25';'D25';'S26';
            'D26';'S27';'D27';'S28';'CH01';'CH02';'CH03';'CH04';
            'CH05';'CH06';'CH07';'CH08';'CH09';'CH10';'CH11';
            'CH12';'CH13';'CH14';'CH15';'CH16';'CH17';'CH18';
            'CH19';'CH20';'CH21';'CH22';'CH23';'CH24';'CH25';
            'CH26';'CH27';'CH28';'CH29';'CH30';'CH31';'CH32';
            'CH33';'CH34';'CH35';'CH36';'CH37';'CH38';'CH39';
            'CH40';'CH41';'CH42';'CH43';'CH44'};
        
        % Add labels
        optode_positions(:,1)=SDCH;
        
        % Print channel and label info to file
        fid = fopen(othersfile, 'wt');
        for i=1:size(optode_positions,1);
            fprintf(fid, '%s,%f,%f,%f\n', optode_positions{i,:});
        end
        fclose(fid);
    end
    
    %% Generate channel positions and add labels for 3x11 x1 probe array
    if probe_array == 4
        
        % Generate channel information
        CH = zeros(52,3);
        for i = 1:3
            CH(1,i) = mean([XYZ(6,i),XYZ(7,i)]);
            CH(2,i) = mean([XYZ(8,i),XYZ(7,i)]);
            CH(3,i) = mean([XYZ(8,i),XYZ(9,i)]);
            CH(4,i) = mean([XYZ(10,i),XYZ(9,i)]);
            CH(5,i) = mean([XYZ(10,i),XYZ(11,i)]);
            CH(6,i) = mean([XYZ(12,i),XYZ(11,i)]);
            CH(7,i) = mean([XYZ(12,i),XYZ(13,i)]);
            CH(8,i) = mean([XYZ(14,i),XYZ(13,i)]);
            CH(9,i) = mean([XYZ(14,i),XYZ(15,i)]);
            CH(10,i) = mean([XYZ(16,i),XYZ(15,i)]);
            CH(11,i) = mean([XYZ(6,i),XYZ(17,i)]);
            CH(12,i) = mean([XYZ(18,i),XYZ(7,i)]);
            CH(13,i) = mean([XYZ(8,i),XYZ(19,i)]);
            CH(14,i) = mean([XYZ(20,i),XYZ(9,i)]);
            CH(15,i) = mean([XYZ(10,i),XYZ(21,i)]);
            CH(16,i) = mean([XYZ(22,i),XYZ(11,i)]);
            CH(17,i) = mean([XYZ(12,i),XYZ(23,i)]);
            CH(18,i) = mean([XYZ(24,i),XYZ(13,i)]);
            CH(19,i) = mean([XYZ(14,i),XYZ(25,i)]);
            CH(20,i) = mean([XYZ(26,i),XYZ(15,i)]);
            CH(21,i) = mean([XYZ(16,i),XYZ(27,i)]);
            CH(22,i) = mean([XYZ(18,i),XYZ(17,i)]);
            CH(23,i) = mean([XYZ(18,i),XYZ(19,i)]);
            CH(24,i) = mean([XYZ(20,i),XYZ(19,i)]);
            CH(25,i) = mean([XYZ(20,i),XYZ(21,i)]);
            CH(26,i) = mean([XYZ(22,i),XYZ(21,i)]);
            CH(27,i) = mean([XYZ(22,i),XYZ(23,i)]);
            CH(28,i) = mean([XYZ(24,i),XYZ(23,i)]);
            CH(29,i) = mean([XYZ(24,i),XYZ(25,i)]);
            CH(30,i) = mean([XYZ(26,i),XYZ(25,i)]);
            CH(31,i) = mean([XYZ(26,i),XYZ(27,i)]);
            CH(32,i) = mean([XYZ(28,i),XYZ(17,i)]);
            CH(33,i) = mean([XYZ(18,i),XYZ(29,i)]);
            CH(34,i) = mean([XYZ(30,i),XYZ(19,i)]);
            CH(35,i) = mean([XYZ(20,i),XYZ(31,i)]);
            CH(36,i) = mean([XYZ(32,i),XYZ(21,i)]);
            CH(37,i) = mean([XYZ(22,i),XYZ(33,i)]);
            CH(38,i) = mean([XYZ(34,i),XYZ(23,i)]);
            CH(39,i) = mean([XYZ(24,i),XYZ(35,i)]);
            CH(40,i) = mean([XYZ(36,i),XYZ(25,i)]);
            CH(41,i) = mean([XYZ(26,i),XYZ(37,i)]);
            CH(42,i) = mean([XYZ(38,i),XYZ(27,i)]);
            CH(43,i) = mean([XYZ(28,i),XYZ(29,i)]);
            CH(44,i) = mean([XYZ(30,i),XYZ(29,i)]);
            CH(45,i) = mean([XYZ(30,i),XYZ(31,i)]);
            CH(46,i) = mean([XYZ(32,i),XYZ(31,i)]);
            CH(47,i) = mean([XYZ(32,i),XYZ(33,i)]);
            CH(48,i) = mean([XYZ(34,i),XYZ(33,i)]);
            CH(49,i) = mean([XYZ(34,i),XYZ(35,i)]);
            CH(50,i) = mean([XYZ(36,i),XYZ(35,i)]);
            CH(51,i) = mean([XYZ(36,i),XYZ(37,i)]);
            CH(52,i) = mean([XYZ(38,i),XYZ(37,i)]);
        end
        
        % Open others file to add channels and labels
        filename = othersfile;
        delimiter = ',';
        formatSpec = '%s%f%f%f%[^\n\r]';
        fileID = fopen(filename,'r');
        optodeArray = textscan(fileID, formatSpec, 'Delimiter', delimiter,  'ReturnOnError', false);
        fclose(fileID);
        
        % Format channel information
        CH=num2cell(CH);
        
        SDX=vertcat(optodeArray{:,2});
        SDY=vertcat(optodeArray{:,3});
        SDZ=vertcat(optodeArray{:,4});
        CHX=vertcat(CH{:,1});
        CHY=vertcat(CH{:,2});
        CHZ=vertcat(CH{:,3});
        
        optode_positions(:,2)=[SDX;CHX];
        optode_positions(:,3)=[SDY;CHY];
        optode_positions(:,4)=[SDZ;CHZ];
        
        optode_positions=num2cell(optode_positions);
        
        % Create optode and channel labels
        SDCH = {'S11';'D11';'S12';'D12';'S13';'D13';'S14';'D14';
            'S15';'D15';'S16';'D16';'S17';'D17';'S18';'D18';'S19';
            'D21';'S21';'D22';'S22';'D23';'S23';'D24';'S24';'D25';
            'S25';'D26';'S26';'D27';'S27';'D28';'S28';'CH01';
            'CH02';'CH03';'CH04';'CH05';'CH06';'CH07';'CH08';
            'CH09';'CH10';'CH11';'CH12';'CH13';'CH14';'CH15';
            'CH16';'CH17';'CH18';'CH19';'CH20';'CH21';'CH22';
            'CH23';'CH24';'CH25';'CH26';'CH27';'CH28';'CH29';
            'CH30';'CH31';'CH32';'CH33';'CH34';'CH35';'CH36';
            'CH37';'CH38';'CH39';'CH40';'CH41';'CH42';'CH43';
            'CH44';'CH45';'CH46';'CH47';'CH48';'CH49';'CH50';
            'CH51';'CH52'};
        
        % Add labels
        optode_positions(:,1)=SDCH;
        
        % Print channel and label information to file
        fid = fopen(othersfile, 'wt');
        for i=1:size(optode_positions,1);
            fprintf(fid, '%s,%f,%f,%f\n', optode_positions{i,:});
        end
        fclose(fid);
    end
    
    %% Format output file for the SPM-fNIRS toolbox (SPM12)
    if (file_output >= 3)
        %% File output for the SPM-fNIRS toolbox (SPM12) - (origin/reference) - all probe arrays
        
        % Modify origin file for SPM-fNIRS (SPM12)
        
        % Open origin file
        delimiter = ',';
        formatSpec = '%s%s%s%s%[^\n\r]';
        fileID = fopen(originfile,'r');
        referenceArray = textscan(fileID, formatSpec, 'Delimiter', delimiter,  'ReturnOnError', false);
        fclose(fileID);
        
        % Allocate imported array to variable column names
        Label = referenceArray{:, 1};
        X = referenceArray{:, 2};
        Y = referenceArray{:, 3};
        Z = referenceArray{:, 4};
        
        % Replace the origin information
        Reference = {'Reference';'NzHS';'IzHS';'ARHS';'ALHS';'Fp1HS';
            'Fp2HS';'FzHS';'F3HS';'F4HS';'F7HS';'F8HS';'CzHS';'C3HS';
            'C4HS';'T3HS';'T4HS';'PzHS';'P3HS';'P4HS';'T5HS';'T6HS';
            'O1HS';'O2HS'};
        
        % Combine all cell arrays
        reference_positions(:,1)=vertcat(Reference);
        reference_positions(:,2)=vertcat(X);
        reference_positions(1,2)={'X'};
        reference_positions(:,3)=vertcat(Y);
        reference_positions(1,3)={'Y'};
        reference_positions(:,4)=vertcat(Z);
        reference_positions(1,4)={'Z'};
        
        % Save the origin information arrays as comma separated values for
        % the SPM-fNIRS toolbox (SPM12). Format: 'reference_positions.csv'
        referencefile = [pathname, 'reference', '_positions.csv'];
        fid = fopen(referencefile, 'wt');
        for i=1:size(reference_positions,1)
            fprintf(fid, '%s, %s, %s, %s\n', reference_positions{i,:});
        end
        fclose(fid);
        
        %% File output for SPM-fNIRS (SPM12) - (others/optode) - all probe arrays
        
        % Modify others file for SPM_fNIRS (SPM 12)
        
        % Open others file
        filename = ('othersfile');
        delimiter = ',';
        formatSpec = '%s%s%s%s%[^\n\r]';
        fileID = fopen(othersfile,'r');
        optodeArray = textscan(fileID, formatSpec, 'Delimiter', delimiter,  'ReturnOnError', false);
        fclose(fileID);

        % Allocate imported array to column variable names
        Optode = optodeArray{:, 1};
        X = optodeArray{:, 2};
        Y = optodeArray{:, 3};
        Z = optodeArray{:, 4};
        
        % Replace the others lables
        Oheader={'Optode'};
        Xheader={'X'};
        Yheader={'Y'};
        Zheader={'Z'};
        
        % Combine all cell arrays
        clear optode_positions
        optode_positions(:,1)=vertcat(Oheader,Optode);
        optode_positions(:,2)=vertcat(Xheader,X);
        optode_positions(:,3)=vertcat(Yheader,Y);
        optode_positions(:,4)=vertcat(Zheader,Z);

        % Save the others information arrays as comma separated values for
        % SPM-fNIRS (SPM12).  Format: 'optode_positions.csv'
        optodefile = [pathname, 'optode', '_positions.csv'];
        fid = fopen(optodefile, 'wt');
        for i=1:size(optode_positions,1)
            fprintf(fid, '%s, %s, %s, %s\n', optode_positions{i,:});
        end
        fclose(fid);
        
        %% Copy channel configuration files to the POS path
        % Depending on how you are processing you spatial registration
        % data, the SPM-fNIRS toolbox sometimes requires the refernce,
        % optode, and channel configuration files.  But, you may get an
        % error if these files are not all in the same folder.  This copies
        % them directly to the same path as all of the other files.  This
        % should save you some time and trouble later.
        
        % 3x3 x2 probe array
        if probe_array == 2
            scriptpath = fileparts(which('pos2spm')); % Find the script path
            configtxtfile = [scriptpath, '/ch_config/3x3x2_ch_config/ch_config.txt']; % Find the TXT file
            configcsvfile = [scriptpath, '/ch_config/3x3x2_ch_config/ch_config.csv']; % Find the CSV file
            copyfile(configtxtfile,pathname)
            copyfile(configcsvfile,pathname)
            clear scriptpath configtxtfile configcsvfile
        end
        
        % 3x5 x2 probe array
        if probe_array == 3
            scriptpath = fileparts(which('pos2spm')); % Find the script path
            configtxtfile = [scriptpath, '/ch_config/3x5x2_ch_config/ch_config.txt']; % Find the TXT file
            configcsvfile = [scriptpath, '/ch_config/3x5x2_ch_config/ch_config.csv']; % Find the CSV file
            copyfile(configtxtfile,pathname)
            copyfile(configcsvfile,pathname)
            clear scriptpath configtxtfile configcsvfile
        end
        
        % 3x11 x1 probe array
        if probe_array == 4
            scriptpath = fileparts(which('pos2spm')); % Find the script path
            configtxtfile = [scriptpath, '/ch_config/3x11x1_ch_config/ch_config.txt']; % Find the TXT file
            configcsvfile = [scriptpath, '/ch_config/3x11x1_ch_config/ch_config.csv']; % Find the CSV file
            copyfile(configtxtfile,pathname)
            copyfile(configcsvfile,pathname)
            clear scriptpath configtxtfile configcsvfile
        end
    end
    
    %% Move the files to the polhemus folder one directory level up from the pathname
    
    % If a folder labeled "Polhemus" already exists, continue to move
    % files.  If a folder labeled "Polhemus" does not exist, make the
    % folder before moving files.
    DIRCHECK = exist([pathname,'../Polhemus'], 'dir');
    if DIRCHECK == 0
        mkdir([pathname, '../Polhemus'])
    end
    
    % Move files
    if file_output == 2
        movefile(originfile, [pathname, '../Polhemus'])
        movefile(othersfile, [pathname, '../Polhemus'])
    end
    if file_output == 3
        movefile(referencefile, [pathname, '../Polhemus'])
        movefile(optodefile, [pathname, '../Polhemus'])
        movefile([pathname, '/ch_config.csv'], [pathname, '../Polhemus'])
        movefile([pathname, '/ch_config.txt'], [pathname, '../Polhemus'])
        delete(originfile)
        delete(othersfile)
    end
    if file_output == 4
        movefile(originfile, [pathname, '../Polhemus'])
        movefile(othersfile, [pathname, '../Polhemus'])
        movefile(referencefile, [pathname, '../Polhemus'])
        movefile(optodefile, [pathname, '../Polhemus'])
        movefile([pathname, '/ch_config.csv'], [pathname, '../Polhemus'])
        movefile([pathname, '/ch_config.txt'], [pathname, '../Polhemus'])
    end
    
    %% Message: Finished
    if file_output == 2
        helpdlg({'You have successfully generated all of the appropriately formated files necessary for spatial registration in NIRS_SPM.'; ''; 'Press "OK" or close to end.'}, 'pos2spm')
    end
    if file_output == 3
        helpdlg({'You have successfully generated all of the appropriately formated files necessary for spatial registration in the spm_fnirs toolbox.'; ''; 'Press "OK" or close to end.'}, 'pos2spm')
    end
    if file_output == 4
        helpdlg({'You have successfully generated all of the appropriately formated files necessary for spatial registration in NIRS_SPM and the spm_fnirs toolbox.'; ''; 'Press "OK" or close to end.'}, 'pos2spm')
    end
    
end

%% Two POS files
if num_pos == 3
    %% Modified pos2csv
    
    % First POS fileparts
    waitfor(helpdlg({'In the next window, you will be prompted to select the FIRST .pos file.'; 'Press "OK" to continue.'}, 'pos2spm'));
    [filename1, pathname, ~] = uigetfile('*.pos', 'Select the .pos file');
    
    % Modified pos2csv
    [~, XYZ1, XYZ_AER_NXYZ1] = ReadPos_modified([pathname filename1]);
    
    originfile1 = [pathname, filename1, '_origin.csv'];
    othersfile1 = [pathname, filename1, '_others.csv'];
    
    % Second POS fileparts
    waitfor(helpdlg({'In the next window, you will be prompted to select the SECOND .pos file.'; 'Press "OK" to continue.'}, 'pos2spm'));
    [filename2, pathname, ~] = uigetfile('*.pos', 'Select the .pos file');
    
    % Modified pos2csv
    [~, XYZ2, XYZ_AER_NXYZ2] = ReadPos_modified([pathname filename2]);
    
    originfile2 = [pathname, filename2, '_origin.csv'];
    othersfile2 = [pathname, filename2, '_others.csv'];
    
    %% For origin file (modified pos2csv)
    
    % First origin file
    fid = fopen(originfile1, 'w');
    fprintf(fid, '"Label","X","Y","Z",\n'); % Header
    fprintf(fid, '"Nz",%f,%f,%f\n', XYZ1(3, :)); % Nz
    fprintf(fid, '"Iz",%f,%f,%f\n', XYZ1(4, :)); % Iz
    fprintf(fid, '"AR",%f,%f,%f\n', XYZ1(2, :)); % AR
    fprintf(fid, '"AL",%f,%f,%f\n', XYZ1(1, :)); % AL
    for k = 1:7
        fprintf(fid, ',,,,\n'); % Fp1, Fp2, FZ, F3, F4, F7, F8
    end
    fprintf(fid, '"Cz",%f,%f,%f\n', XYZ1(5, :)); % Cz
    for k = 1:11
        fprintf(fid, ',,,,\n'); % C3, C4, T3, T4, Pz, P3, P4, T5, T6, O1, O2
    end
    fclose(fid);
    
    % Second origin file
    fid = fopen(originfile2, 'w');
    fprintf(fid, '"Label","X","Y","Z",\n'); % Header
    fprintf(fid, '"Nz",%f,%f,%f\n', XYZ2(3, :)); % Nz
    fprintf(fid, '"Iz",%f,%f,%f\n', XYZ2(4, :)); % Iz
    fprintf(fid, '"AR",%f,%f,%f\n', XYZ2(2, :)); % AR
    fprintf(fid, '"AL",%f,%f,%f\n', XYZ2(1, :)); % AL
    for k = 1:7
        fprintf(fid, ',,,,\n'); % Fp1, Fp2, FZ, F3, F4, F7, F8
    end
    fprintf(fid, '"Cz",%f,%f,%f\n', XYZ2(5, :)); % Cz
    for k = 1:11
        fprintf(fid, ',,,,\n'); % C3, C4, T3, T4, Pz, P3, P4, T5, T6, O1, O2
    end
    fclose(fid);
    
    %% Average both origin files
    
    % Average measurements
    originavg = zeros(5,3);
    for i = 1:3
        originavg(1,i) = mean([XYZ1(1,i),XYZ2(1,i)]); % AL
        originavg(2,i) = mean([XYZ1(2,i),XYZ2(2,i)]); % AR
        originavg(3,i) = mean([XYZ1(3,i),XYZ2(3,i)]); % Nz
        originavg(4,i) = mean([XYZ1(4,i),XYZ2(4,i)]); % Iz
        originavg(5,i) = mean([XYZ1(5,i),XYZ2(5,i)]); % Cz
    end
    
    % Generate averaged origin file
    originfile = [pathname, ParticipantID, '_origin.csv'];
    
    % Save averaged information to averaged origin file
    fid = fopen(originfile, 'w');
    fprintf(fid, '"Label","X","Y","Z",\n'); % Header
    fprintf(fid, '"Nz",%f,%f,%f\n', originavg(3, :)); % Nz
    fprintf(fid, '"Iz",%f,%f,%f\n', originavg(4, :)); % Iz
    fprintf(fid, '"AR",%f,%f,%f\n', originavg(2, :)); % AR
    fprintf(fid, '"AL",%f,%f,%f\n', originavg(1, :)); % AL
    for k = 1:7
        fprintf(fid, ',,,,\n'); % Fp1, Fp2, Fz, F3, F4, F7, F8
    end
    fprintf(fid, '"Cz",%f,%f,%f\n', originavg(5, :)); % Cz
    for k = 1:11
        fprintf(fid, ',,,,\n'); % C3, C4, T3, T4, Pz, P3, P4, T5, T6, O1, O2
    end
    fclose(fid);
    
    % Delete unnecessary files
    delete(originfile1)
    delete(originfile2)
    
    %% Form others file (modified pos2csv)
    
    % First others file
    fid = fopen(othersfile1, 'w');
    for k = 6:size(XYZ1, 1)-1
        fprintf(fid, '%f,%f,%f\n', XYZ1(k, :));
    end
    fclose(fid);
    clearvars fid ans k l
    
    % Second others file
    fid = fopen(othersfile2, 'w');
    for k = 6:size(XYZ2, 1)-1
        fprintf(fid, '%f,%f,%f\n', XYZ2(k, :));
    end
    fclose(fid);
    
    %% Generate channel positions, average files, and add labels for 3x3 x2 probe array
    if probe_array == 2
        
        % Open others file 1
        filename = othersfile1;
        delimiter = ',';
        formatSpec = '%f%f%f%[^\n\r]';
        fileID = fopen(filename,'r');
        optodeArray1 = textscan(fileID, formatSpec, 'Delimiter', delimiter,  'ReturnOnError', false);
        fclose(fileID);
        
        % Restructure Others1 information
        optode1Array(:,1)=vertcat(optodeArray1{:,1});
        optode1Array(:,2)=vertcat(optodeArray1{:,2});
        optode1Array(:,3)=vertcat(optodeArray1{:,3});
        
        % Open others file 2
        filename = othersfile2;
        delimiter = ',';
        formatSpec = '%f%f%f%[^\n\r]';
        fileID = fopen(filename,'r');
        optodeArray2 = textscan(fileID, formatSpec, 'Delimiter', delimiter,  'ReturnOnError', false);
        fclose(fileID);
        
        optode2Array(:,1)=vertcat(optodeArray2{:,1});
        optode2Array(:,2)=vertcat(optodeArray2{:,2});
        optode2Array(:,3)=vertcat(optodeArray2{:,3});
        
        % Average source and detector positions
        optodeArray = zeros(18,3);
        for i = 1:3
            optodeArray(1,i) = mean([optode1Array(1,i),optode2Array(1,i)]);
            optodeArray(2,i) = mean([optode1Array(2,i),optode2Array(2,i)]);
            optodeArray(3,i) = mean([optode1Array(3,i),optode2Array(3,i)]);
            optodeArray(4,i) = mean([optode1Array(4,i),optode2Array(4,i)]);
            optodeArray(5,i) = mean([optode1Array(5,i),optode2Array(5,i)]);
            optodeArray(6,i) = mean([optode1Array(6,i),optode2Array(6,i)]);
            optodeArray(7,i) = mean([optode1Array(7,i),optode2Array(7,i)]);
            optodeArray(8,i) = mean([optode1Array(8,i),optode2Array(8,i)]);
            optodeArray(9,i) = mean([optode1Array(9,i),optode2Array(9,i)]);
            optodeArray(10,i) = mean([optode1Array(10,i),optode2Array(10,i)]);
            optodeArray(11,i) = mean([optode1Array(11,i),optode2Array(11,i)]);
            optodeArray(12,i) = mean([optode1Array(12,i),optode2Array(12,i)]);
            optodeArray(13,i) = mean([optode1Array(13,i),optode2Array(13,i)]);
            optodeArray(14,i) = mean([optode1Array(14,i),optode2Array(14,i)]);
            optodeArray(15,i) = mean([optode1Array(15,i),optode2Array(15,i)]);
            optodeArray(16,i) = mean([optode1Array(16,i),optode2Array(16,i)]);
            optodeArray(17,i) = mean([optode1Array(17,i),optode2Array(17,i)]);
            optodeArray(18,i) = mean([optode1Array(18,i),optode2Array(18,i)]);
        end
        
        CH1 = zeros(24,3); % Others file 1
        for i = 1:3
            CH1(1,i) = mean([XYZ1(6,i),XYZ1(7,i)]);
            CH1(2,i) = mean([XYZ1(8,i),XYZ1(7,i)]);
            CH1(3,i) = mean([XYZ1(6,i),XYZ1(9,i)]);
            CH1(4,i) = mean([XYZ1(10,i),XYZ1(7,i)]);
            CH1(5,i) = mean([XYZ1(8,i),XYZ1(11,i)]);
            CH1(6,i) = mean([XYZ1(10,i),XYZ1(9,i)]);
            CH1(7,i) = mean([XYZ1(10,i),XYZ1(11,i)]);
            CH1(8,i) = mean([XYZ1(12,i),XYZ1(9,i)]);
            CH1(9,i) = mean([XYZ1(10,i),XYZ1(13,i)]);
            CH1(10,i) = mean([XYZ1(14,i),XYZ1(11,i)]);
            CH1(11,i) = mean([XYZ1(12,i),XYZ1(13,i)]);
            CH1(12,i) = mean([XYZ1(14,i),XYZ1(13,i)]);
            CH1(13,i) = mean([XYZ1(15,i),XYZ1(16,i)]);
            CH1(14,i) = mean([XYZ1(17,i),XYZ1(16,i)]);
            CH1(15,i) = mean([XYZ1(15,i),XYZ1(18,i)]);
            CH1(16,i) = mean([XYZ1(19,i),XYZ1(16,i)]);
            CH1(17,i) = mean([XYZ1(17,i),XYZ1(20,i)]);
            CH1(18,i) = mean([XYZ1(19,i),XYZ1(18,i)]);
            CH1(19,i) = mean([XYZ1(19,i),XYZ1(20,i)]);
            CH1(20,i) = mean([XYZ1(21,i),XYZ1(18,i)]);
            CH1(21,i) = mean([XYZ1(19,i),XYZ1(22,i)]);
            CH1(22,i) = mean([XYZ1(23,i),XYZ1(20,i)]);
            CH1(23,i) = mean([XYZ1(21,i),XYZ1(22,i)]);
            CH1(24,i) = mean([XYZ1(23,i),XYZ1(22,i)]);
        end
        
        CH2 = zeros(24,3); % Others file 2
        for i = 1:3
            CH2(1,i) = mean([XYZ2(6,i),XYZ2(7,i)]);
            CH2(2,i) = mean([XYZ2(8,i),XYZ2(7,i)]);
            CH2(3,i) = mean([XYZ2(6,i),XYZ2(9,i)]);
            CH2(4,i) = mean([XYZ2(10,i),XYZ2(7,i)]);
            CH2(5,i) = mean([XYZ2(8,i),XYZ2(11,i)]);
            CH2(6,i) = mean([XYZ2(10,i),XYZ2(9,i)]);
            CH2(7,i) = mean([XYZ2(10,i),XYZ2(11,i)]);
            CH2(8,i) = mean([XYZ2(12,i),XYZ2(9,i)]);
            CH2(9,i) = mean([XYZ2(10,i),XYZ2(13,i)]);
            CH2(10,i) = mean([XYZ2(14,i),XYZ2(11,i)]);
            CH2(11,i) = mean([XYZ2(12,i),XYZ2(13,i)]);
            CH2(12,i) = mean([XYZ2(14,i),XYZ2(13,i)]);
            CH2(13,i) = mean([XYZ2(15,i),XYZ2(16,i)]);
            CH2(14,i) = mean([XYZ2(17,i),XYZ2(16,i)]);
            CH2(15,i) = mean([XYZ2(15,i),XYZ2(18,i)]);
            CH2(16,i) = mean([XYZ2(19,i),XYZ2(16,i)]);
            CH2(17,i) = mean([XYZ2(17,i),XYZ2(20,i)]);
            CH2(18,i) = mean([XYZ2(19,i),XYZ2(18,i)]);
            CH2(19,i) = mean([XYZ2(19,i),XYZ2(20,i)]);
            CH2(20,i) = mean([XYZ2(21,i),XYZ2(18,i)]);
            CH2(21,i) = mean([XYZ2(19,i),XYZ2(22,i)]);
            CH2(22,i) = mean([XYZ2(23,i),XYZ2(20,i)]);
            CH2(23,i) = mean([XYZ2(21,i),XYZ2(22,i)]);
            CH2(24,i) = mean([XYZ2(23,i),XYZ2(22,i)]);
        end
        
        CH = zeros(24,3); % Others file average
        for i = 1:3
            CH(1,i) = mean([CH1(1,i),CH2(1,i)]);
            CH(2,i) = mean([CH1(2,i),CH2(2,i)]);
            CH(3,i) = mean([CH1(3,i),CH2(3,i)]);
            CH(4,i) = mean([CH1(4,i),CH2(4,i)]);
            CH(5,i) = mean([CH1(5,i),CH2(5,i)]);
            CH(6,i) = mean([CH1(6,i),CH2(6,i)]);
            CH(7,i) = mean([CH1(7,i),CH2(7,i)]);
            CH(8,i) = mean([CH1(8,i),CH2(8,i)]);
            CH(9,i) = mean([CH1(9,i),CH2(9,i)]);
            CH(10,i) = mean([CH1(10,i),CH2(10,i)]);
            CH(11,i) = mean([CH1(11,i),CH2(11,i)]);
            CH(12,i) = mean([CH1(12,i),CH2(12,i)]);
            CH(13,i) = mean([CH1(13,i),CH2(13,i)]);
            CH(14,i) = mean([CH1(14,i),CH2(14,i)]);
            CH(15,i) = mean([CH1(15,i),CH2(15,i)]);
            CH(16,i) = mean([CH1(16,i),CH2(16,i)]);
            CH(17,i) = mean([CH1(17,i),CH2(17,i)]);
            CH(18,i) = mean([CH1(18,i),CH2(18,i)]);
            CH(19,i) = mean([CH1(19,i),CH2(19,i)]);
            CH(20,i) = mean([CH1(20,i),CH2(20,i)]);
            CH(21,i) = mean([CH1(21,i),CH2(21,i)]);
            CH(22,i) = mean([CH1(22,i),CH2(22,i)]);
            CH(23,i) = mean([CH1(23,i),CH2(23,i)]);
            CH(24,i) = mean([CH1(24,i),CH2(24,i)]);
        end
        
        % Format channel information
        CH=num2cell(CH);
        optodeArray=num2cell(optodeArray);
        
        SDX=vertcat(optodeArray{:,1});
        SDY=vertcat(optodeArray{:,2});
        SDZ=vertcat(optodeArray{:,3});
        CHX=vertcat(CH{:,1});
        CHY=vertcat(CH{:,2});
        CHZ=vertcat(CH{:,3});
        
        optode_positions(:,2)=[SDX;CHX];
        optode_positions(:,3)=[SDY;CHY];
        optode_positions(:,4)=[SDZ;CHZ];
        
        optode_positions=num2cell(optode_positions);
        
        % Create optode and channel labels
        SDCH = {'S19';'D16';'S16';'D18';'S18';'D15';'S10';'D17';
            'S17';'S12';'D13';'S15';'D11';'S13';'D14';'S11';'D12';
            'S14';'CH01';'CH02';'CH03';'CH04';'CH05';'CH06';
            'CH07';'CH08';'CH09';'CH10';'CH11';'CH12';'CH13';
            'CH14';'CH15';'CH16';'CH17';'CH18';'CH19';'CH20';
            'CH21';'CH22';'CH23';'CH24'};
        
        % Add labels
        optode_positions(:,1)=SDCH;
        
        % Generate averaged others file
        othersfile = [pathname, ParticipantID, '_others.csv'];
        
        % Pring the channel and label information to the file
        fid = fopen(othersfile, 'wt');
        for i=1:size(optode_positions,1);
            fprintf(fid, '%s,%f,%f,%f\n', optode_positions{i,:});
        end
        fclose(fid);
        
        % Delete unnecessary files
        delete(othersfile1)
        delete(othersfile2)
        
    end
    
    %% Generate channel positions, average files, and add labels for 3x5 x2 probe array
    if probe_array == 3
        
        % Open others file 1
        filename = othersfile1;
        delimiter = ',';
        formatSpec = '%f%f%f%[^\n\r]';
        fileID = fopen(filename,'r');
        optodeArray1 = textscan(fileID, formatSpec, 'Delimiter', delimiter,  'ReturnOnError', false);
        fclose(fileID);
        
        optode1Array(:,1)=vertcat(optodeArray1{:,1});
        optode1Array(:,2)=vertcat(optodeArray1{:,2});
        optode1Array(:,3)=vertcat(optodeArray1{:,3});
        
        % Open others file 2
        filename = othersfile2;
        delimiter = ',';
        formatSpec = '%f%f%f%[^\n\r]';
        fileID = fopen(filename,'r');
        optodeArray2 = textscan(fileID, formatSpec, 'Delimiter', delimiter,  'ReturnOnError', false);
        fclose(fileID);
        
        optode2Array(:,1)=vertcat(optodeArray2{:,1});
        optode2Array(:,2)=vertcat(optodeArray2{:,2});
        optode2Array(:,3)=vertcat(optodeArray2{:,3});
        
        % Average source and detector positions
        optodeArray = zeros(30,3);
        for i = 1:3
            optodeArray(1,i) = mean([optode1Array(1,i),optode2Array(1,i)]);
            optodeArray(2,i) = mean([optode1Array(2,i),optode2Array(2,i)]);
            optodeArray(3,i) = mean([optode1Array(3,i),optode2Array(3,i)]);
            optodeArray(4,i) = mean([optode1Array(4,i),optode2Array(4,i)]);
            optodeArray(5,i) = mean([optode1Array(5,i),optode2Array(5,i)]);
            optodeArray(6,i) = mean([optode1Array(6,i),optode2Array(6,i)]);
            optodeArray(7,i) = mean([optode1Array(7,i),optode2Array(7,i)]);
            optodeArray(8,i) = mean([optode1Array(8,i),optode2Array(8,i)]);
            optodeArray(9,i) = mean([optode1Array(9,i),optode2Array(9,i)]);
            optodeArray(10,i) = mean([optode1Array(10,i),optode2Array(10,i)]);
            optodeArray(11,i) = mean([optode1Array(11,i),optode2Array(11,i)]);
            optodeArray(12,i) = mean([optode1Array(12,i),optode2Array(12,i)]);
            optodeArray(13,i) = mean([optode1Array(13,i),optode2Array(13,i)]);
            optodeArray(14,i) = mean([optode1Array(14,i),optode2Array(14,i)]);
            optodeArray(15,i) = mean([optode1Array(15,i),optode2Array(15,i)]);
            optodeArray(16,i) = mean([optode1Array(16,i),optode2Array(16,i)]);
            optodeArray(17,i) = mean([optode1Array(17,i),optode2Array(17,i)]);
            optodeArray(18,i) = mean([optode1Array(18,i),optode2Array(18,i)]);
            optodeArray(19,i) = mean([optode1Array(19,i),optode2Array(19,i)]);
            optodeArray(20,i) = mean([optode1Array(20,i),optode2Array(20,i)]);
            optodeArray(21,i) = mean([optode1Array(21,i),optode2Array(21,i)]);
            optodeArray(22,i) = mean([optode1Array(22,i),optode2Array(22,i)]);
            optodeArray(23,i) = mean([optode1Array(23,i),optode2Array(23,i)]);
            optodeArray(24,i) = mean([optode1Array(24,i),optode2Array(24,i)]);
            optodeArray(25,i) = mean([optode1Array(25,i),optode2Array(25,i)]);
            optodeArray(26,i) = mean([optode1Array(26,i),optode2Array(26,i)]);
            optodeArray(27,i) = mean([optode1Array(27,i),optode2Array(27,i)]);
            optodeArray(28,i) = mean([optode1Array(28,i),optode2Array(28,i)]);
            optodeArray(29,i) = mean([optode1Array(29,i),optode2Array(29,i)]);
            optodeArray(30,i) = mean([optode1Array(30,i),optode2Array(30,i)]);
        end
        
        % Generate channel positions and average
        CH1 = zeros(44,3); % Others file 1
        for i = 1:3
            CH1(1,i) = mean([XYZ1(6,i),XYZ1(7,i)]);
            CH1(2,i) = mean([XYZ1(7,i),XYZ1(8,i)]);
            CH1(3,i) = mean([XYZ1(8,i),XYZ1(9,i)]);
            CH1(4,i) = mean([XYZ1(9,i),XYZ1(10,i)]);
            CH1(5,i) = mean([XYZ1(6,i),XYZ1(11,i)]);
            CH1(6,i) = mean([XYZ1(7,i),XYZ1(12,i)]);
            CH1(7,i) = mean([XYZ1(8,i),XYZ1(13,i)]);
            CH1(8,i) = mean([XYZ1(9,i),XYZ1(14,i)]);
            CH1(9,i) = mean([XYZ1(10,i),XYZ1(15,i)]);
            CH1(10,i) = mean([XYZ1(11,i),XYZ1(12,i)]);
            CH1(11,i) = mean([XYZ1(12,i),XYZ1(13,i)]);
            CH1(12,i) = mean([XYZ1(13,i),XYZ1(14,i)]);
            CH1(13,i) = mean([XYZ1(14,i),XYZ1(15,i)]);
            CH1(14,i) = mean([XYZ1(11,i),XYZ1(16,i)]);
            CH1(15,i) = mean([XYZ1(12,i),XYZ1(17,i)]);
            CH1(16,i) = mean([XYZ1(13,i),XYZ1(18,i)]);
            CH1(17,i) = mean([XYZ1(14,i),XYZ1(19,i)]);
            CH1(18,i) = mean([XYZ1(15,i),XYZ1(20,i)]);
            CH1(19,i) = mean([XYZ1(16,i),XYZ1(17,i)]);
            CH1(20,i) = mean([XYZ1(17,i),XYZ1(18,i)]);
            CH1(21,i) = mean([XYZ1(18,i),XYZ1(19,i)]);
            CH1(22,i) = mean([XYZ1(19,i),XYZ1(20,i)]);
            CH1(23,i) = mean([XYZ1(21,i),XYZ1(22,i)]);
            CH1(24,i) = mean([XYZ1(22,i),XYZ1(23,i)]);
            CH1(25,i) = mean([XYZ1(23,i),XYZ1(24,i)]);
            CH1(26,i) = mean([XYZ1(24,i),XYZ1(25,i)]);
            CH1(27,i) = mean([XYZ1(21,i),XYZ1(26,i)]);
            CH1(28,i) = mean([XYZ1(22,i),XYZ1(27,i)]);
            CH1(29,i) = mean([XYZ1(23,i),XYZ1(28,i)]);
            CH1(30,i) = mean([XYZ1(24,i),XYZ1(29,i)]);
            CH1(31,i) = mean([XYZ1(25,i),XYZ1(30,i)]);
            CH1(32,i) = mean([XYZ1(26,i),XYZ1(27,i)]);
            CH1(33,i) = mean([XYZ1(27,i),XYZ1(28,i)]);
            CH1(34,i) = mean([XYZ1(28,i),XYZ1(29,i)]);
            CH1(35,i) = mean([XYZ1(29,i),XYZ1(30,i)]);
            CH1(36,i) = mean([XYZ1(26,i),XYZ1(31,i)]);
            CH1(37,i) = mean([XYZ1(27,i),XYZ1(32,i)]);
            CH1(38,i) = mean([XYZ1(28,i),XYZ1(33,i)]);
            CH1(39,i) = mean([XYZ1(29,i),XYZ1(34,i)]);
            CH1(40,i) = mean([XYZ1(30,i),XYZ1(35,i)]);
            CH1(41,i) = mean([XYZ1(31,i),XYZ1(32,i)]);
            CH1(42,i) = mean([XYZ1(32,i),XYZ1(33,i)]);
            CH1(43,i) = mean([XYZ1(33,i),XYZ1(34,i)]);
            CH1(44,i) = mean([XYZ1(34,i),XYZ1(35,i)]);
        end
        
        CH2 = zeros(44,3); % Others file 2
        for i = 1:3
            CH2(1,i) = mean([XYZ2(6,i),XYZ2(7,i)]);
            CH2(2,i) = mean([XYZ2(7,i),XYZ2(8,i)]);
            CH2(3,i) = mean([XYZ2(8,i),XYZ2(9,i)]);
            CH2(4,i) = mean([XYZ2(9,i),XYZ2(10,i)]);
            CH2(5,i) = mean([XYZ2(6,i),XYZ2(11,i)]);
            CH2(6,i) = mean([XYZ2(7,i),XYZ2(12,i)]);
            CH2(7,i) = mean([XYZ2(8,i),XYZ2(13,i)]);
            CH2(8,i) = mean([XYZ2(9,i),XYZ2(14,i)]);
            CH2(9,i) = mean([XYZ2(10,i),XYZ2(15,i)]);
            CH2(10,i) = mean([XYZ2(11,i),XYZ2(12,i)]);
            CH2(11,i) = mean([XYZ2(12,i),XYZ2(13,i)]);
            CH2(12,i) = mean([XYZ2(13,i),XYZ2(14,i)]);
            CH2(13,i) = mean([XYZ2(14,i),XYZ2(15,i)]);
            CH2(14,i) = mean([XYZ2(11,i),XYZ2(16,i)]);
            CH2(15,i) = mean([XYZ2(12,i),XYZ2(17,i)]);
            CH2(16,i) = mean([XYZ2(13,i),XYZ2(18,i)]);
            CH2(17,i) = mean([XYZ2(14,i),XYZ2(19,i)]);
            CH2(18,i) = mean([XYZ2(15,i),XYZ2(20,i)]);
            CH2(19,i) = mean([XYZ2(16,i),XYZ2(17,i)]);
            CH2(20,i) = mean([XYZ2(17,i),XYZ2(18,i)]);
            CH2(21,i) = mean([XYZ2(18,i),XYZ2(19,i)]);
            CH2(22,i) = mean([XYZ2(19,i),XYZ2(20,i)]);
            CH2(23,i) = mean([XYZ2(21,i),XYZ2(22,i)]);
            CH2(24,i) = mean([XYZ2(22,i),XYZ2(23,i)]);
            CH2(25,i) = mean([XYZ2(23,i),XYZ2(24,i)]);
            CH2(26,i) = mean([XYZ2(24,i),XYZ2(25,i)]);
            CH2(27,i) = mean([XYZ2(21,i),XYZ2(26,i)]);
            CH2(28,i) = mean([XYZ2(22,i),XYZ2(27,i)]);
            CH2(29,i) = mean([XYZ2(23,i),XYZ2(28,i)]);
            CH2(30,i) = mean([XYZ2(24,i),XYZ2(29,i)]);
            CH2(31,i) = mean([XYZ2(25,i),XYZ2(30,i)]);
            CH2(32,i) = mean([XYZ2(26,i),XYZ2(27,i)]);
            CH2(33,i) = mean([XYZ2(27,i),XYZ2(28,i)]);
            CH2(34,i) = mean([XYZ2(28,i),XYZ2(29,i)]);
            CH2(35,i) = mean([XYZ2(29,i),XYZ2(30,i)]);
            CH2(36,i) = mean([XYZ2(26,i),XYZ2(31,i)]);
            CH2(37,i) = mean([XYZ2(27,i),XYZ2(32,i)]);
            CH2(38,i) = mean([XYZ2(28,i),XYZ2(33,i)]);
            CH2(39,i) = mean([XYZ2(29,i),XYZ2(34,i)]);
            CH2(40,i) = mean([XYZ2(30,i),XYZ2(35,i)]);
            CH2(41,i) = mean([XYZ2(31,i),XYZ2(32,i)]);
            CH2(42,i) = mean([XYZ2(32,i),XYZ2(33,i)]);
            CH2(43,i) = mean([XYZ2(33,i),XYZ2(34,i)]);
            CH2(44,i) = mean([XYZ2(34,i),XYZ2(35,i)]);
        end
        
        CH = zeros(44,3); % OThers file average
        for i = 1:3
            CH(1,i) = mean([CH1(1,i),CH2(1,i)]);
            CH(2,i) = mean([CH1(2,i),CH2(2,i)]);
            CH(3,i) = mean([CH1(3,i),CH2(3,i)]);
            CH(4,i) = mean([CH1(4,i),CH2(4,i)]);
            CH(5,i) = mean([CH1(5,i),CH2(5,i)]);
            CH(6,i) = mean([CH1(6,i),CH2(6,i)]);
            CH(7,i) = mean([CH1(7,i),CH2(7,i)]);
            CH(8,i) = mean([CH1(8,i),CH2(8,i)]);
            CH(9,i) = mean([CH1(9,i),CH2(9,i)]);
            CH(10,i) = mean([CH1(10,i),CH2(10,i)]);
            CH(11,i) = mean([CH1(11,i),CH2(11,i)]);
            CH(12,i) = mean([CH1(12,i),CH2(12,i)]);
            CH(13,i) = mean([CH1(13,i),CH2(13,i)]);
            CH(14,i) = mean([CH1(14,i),CH2(14,i)]);
            CH(15,i) = mean([CH1(15,i),CH2(15,i)]);
            CH(16,i) = mean([CH1(16,i),CH2(16,i)]);
            CH(17,i) = mean([CH1(17,i),CH2(17,i)]);
            CH(18,i) = mean([CH1(18,i),CH2(18,i)]);
            CH(19,i) = mean([CH1(19,i),CH2(19,i)]);
            CH(20,i) = mean([CH1(20,i),CH2(20,i)]);
            CH(21,i) = mean([CH1(21,i),CH2(21,i)]);
            CH(22,i) = mean([CH1(22,i),CH2(22,i)]);
            CH(23,i) = mean([CH1(23,i),CH2(23,i)]);
            CH(24,i) = mean([CH1(24,i),CH2(24,i)]);
            CH(25,i) = mean([CH1(25,i),CH2(25,i)]);
            CH(26,i) = mean([CH1(26,i),CH2(26,i)]);
            CH(27,i) = mean([CH1(27,i),CH2(27,i)]);
            CH(28,i) = mean([CH1(28,i),CH2(28,i)]);
            CH(29,i) = mean([CH1(29,i),CH2(29,i)]);
            CH(30,i) = mean([CH1(30,i),CH2(30,i)]);
            CH(31,i) = mean([CH1(31,i),CH2(31,i)]);
            CH(32,i) = mean([CH1(32,i),CH2(32,i)]);
            CH(33,i) = mean([CH1(33,i),CH2(33,i)]);
            CH(34,i) = mean([CH1(34,i),CH2(34,i)]);
            CH(35,i) = mean([CH1(35,i),CH2(35,i)]);
            CH(36,i) = mean([CH1(36,i),CH2(36,i)]);
            CH(37,i) = mean([CH1(37,i),CH2(37,i)]);
            CH(38,i) = mean([CH1(38,i),CH2(38,i)]);
            CH(39,i) = mean([CH1(39,i),CH2(39,i)]);
            CH(40,i) = mean([CH1(40,i),CH2(40,i)]);
            CH(41,i) = mean([CH1(41,i),CH2(41,i)]);
            CH(42,i) = mean([CH1(42,i),CH2(43,i)]);
            CH(43,i) = mean([CH1(43,i),CH2(43,i)]);
            CH(44,i) = mean([CH1(44,i),CH2(44,i)]);
        end
        
        % Format channel information
        CH=num2cell(CH);
        optodeArray=num2cell(optodeArray);
        
        SDX=vertcat(optodeArray{:,1});
        SDY=vertcat(optodeArray{:,2});
        SDZ=vertcat(optodeArray{:,3});
        CHX=vertcat(CH{:,1});
        CHY=vertcat(CH{:,2});
        CHZ=vertcat(CH{:,3});
        
        optode_positions(:,2)=[SDX;CHX];
        optode_positions(:,3)=[SDY;CHY];
        optode_positions(:,4)=[SDZ;CHZ];
        
        optode_positions=num2cell(optode_positions);
        
        % Create optode and channel labels
        SDCH = {'S11';'D11';'S12';'D12';'S13';'D13';'S14';'D14';
            'S15';'D15';'S16';'D16';'S17';'D17';'S18';'S21';'D21';
            'S22';'D22';'S23';'D23';'S24';'D24';'S25';'D25';'S26';
            'D26';'S27';'D27';'S28';'CH01';'CH02';'CH03';'CH04';
            'CH05';'CH06';'CH07';'CH08';'CH09';'CH10';'CH11';
            'CH12';'CH13';'CH14';'CH15';'CH16';'CH17';'CH18';
            'CH19';'CH20';'CH21';'CH22';'CH23';'CH24';'CH25';
            'CH26';'CH27';'CH28';'CH29';'CH30';'CH31';'CH32';
            'CH33';'CH34';'CH35';'CH36';'CH37';'CH38';'CH39';
            'CH40';'CH41';'CH42';'CH43';'CH44'};
        
        % Add labels
        optode_positions(:,1)=SDCH;
        
        % Generage averaged others file
        othersfile = [pathname, ParticipantID, '_others.csv'];
        
        % Print channel and label information to file
        fid = fopen(othersfile, 'wt');
        for i=1:size(optode_positions,1);
            fprintf(fid, '%s,%f,%f,%f\n', optode_positions{i,:});
        end
        fclose(fid);
        
        % Delete unnecessary files
        delete(othersfile1)
        delete(othersfile2)
        
    end
    
    %% Generate channel positions, average files, and add labels for 3x11 x1 probe array
    if probe_array == 4
        
        % Open others file 1
        filename = othersfile1;
        delimiter = ',';
        formatSpec = '%f%f%f%[^\n\r]';
        fileID = fopen(filename,'r');
        optodeArray1 = textscan(fileID, formatSpec, 'Delimiter', delimiter,  'ReturnOnError', false);
        fclose(fileID);
        
        % Restructure others1 information
        optode1Array(:,1)=vertcat(optodeArray1{:,1});
        optode1Array(:,2)=vertcat(optodeArray1{:,2});
        optode1Array(:,3)=vertcat(optodeArray1{:,3});
        
        % Open others file 2
        filename = othersfile2;
        delimiter = ',';
        formatSpec = '%f%f%f%[^\n\r]';
        fileID = fopen(filename,'r');
        optodeArray2 = textscan(fileID, formatSpec, 'Delimiter', delimiter,  'ReturnOnError', false);
        fclose(fileID);
        
        optode2Array(:,1)=vertcat(optodeArray2{:,1});
        optode2Array(:,2)=vertcat(optodeArray2{:,2});
        optode2Array(:,3)=vertcat(optodeArray2{:,3});
        
        % Average source and detector positions
        optodeArray = zeros(33,3);
        for i = 1:3
            optodeArray(1,i) = mean([optode1Array(1,i),optode2Array(1,i)]);
            optodeArray(2,i) = mean([optode1Array(2,i),optode2Array(2,i)]);
            optodeArray(3,i) = mean([optode1Array(3,i),optode2Array(3,i)]);
            optodeArray(4,i) = mean([optode1Array(4,i),optode2Array(4,i)]);
            optodeArray(5,i) = mean([optode1Array(5,i),optode2Array(5,i)]);
            optodeArray(6,i) = mean([optode1Array(6,i),optode2Array(6,i)]);
            optodeArray(7,i) = mean([optode1Array(7,i),optode2Array(7,i)]);
            optodeArray(8,i) = mean([optode1Array(8,i),optode2Array(8,i)]);
            optodeArray(9,i) = mean([optode1Array(9,i),optode2Array(9,i)]);
            optodeArray(10,i) = mean([optode1Array(10,i),optode2Array(10,i)]);
            optodeArray(11,i) = mean([optode1Array(11,i),optode2Array(11,i)]);
            optodeArray(12,i) = mean([optode1Array(12,i),optode2Array(12,i)]);
            optodeArray(13,i) = mean([optode1Array(13,i),optode2Array(13,i)]);
            optodeArray(14,i) = mean([optode1Array(14,i),optode2Array(14,i)]);
            optodeArray(15,i) = mean([optode1Array(15,i),optode2Array(15,i)]);
            optodeArray(16,i) = mean([optode1Array(16,i),optode2Array(16,i)]);
            optodeArray(17,i) = mean([optode1Array(17,i),optode2Array(17,i)]);
            optodeArray(18,i) = mean([optode1Array(18,i),optode2Array(18,i)]);
            optodeArray(19,i) = mean([optode1Array(19,i),optode2Array(19,i)]);
            optodeArray(20,i) = mean([optode1Array(20,i),optode2Array(20,i)]);
            optodeArray(21,i) = mean([optode1Array(21,i),optode2Array(21,i)]);
            optodeArray(22,i) = mean([optode1Array(22,i),optode2Array(22,i)]);
            optodeArray(23,i) = mean([optode1Array(23,i),optode2Array(23,i)]);
            optodeArray(24,i) = mean([optode1Array(24,i),optode2Array(24,i)]);
            optodeArray(25,i) = mean([optode1Array(25,i),optode2Array(25,i)]);
            optodeArray(26,i) = mean([optode1Array(26,i),optode2Array(26,i)]);
            optodeArray(27,i) = mean([optode1Array(27,i),optode2Array(27,i)]);
            optodeArray(28,i) = mean([optode1Array(28,i),optode2Array(28,i)]);
            optodeArray(29,i) = mean([optode1Array(29,i),optode2Array(29,i)]);
            optodeArray(30,i) = mean([optode1Array(30,i),optode2Array(30,i)]);
            optodeArray(31,i) = mean([optode1Array(31,i),optode2Array(31,i)]);
            optodeArray(32,i) = mean([optode1Array(32,i),optode2Array(32,i)]);
            optodeArray(33,i) = mean([optode1Array(33,i),optode2Array(33,i)]);
        end
        
        % Generate channel positions and average
        CH1 = zeros(52,3); % Others file 1
        for i = 1:3
            CH1(1,i) = mean([XYZ1(6,i),XYZ1(7,i)]);
            CH1(2,i) = mean([XYZ1(8,i),XYZ1(7,i)]);
            CH1(3,i) = mean([XYZ1(8,i),XYZ1(9,i)]);
            CH1(4,i) = mean([XYZ1(10,i),XYZ1(9,i)]);
            CH1(5,i) = mean([XYZ1(10,i),XYZ1(11,i)]);
            CH1(6,i) = mean([XYZ1(12,i),XYZ1(11,i)]);
            CH1(7,i) = mean([XYZ1(12,i),XYZ1(13,i)]);
            CH1(8,i) = mean([XYZ1(14,i),XYZ1(13,i)]);
            CH1(9,i) = mean([XYZ1(14,i),XYZ1(15,i)]);
            CH1(10,i) = mean([XYZ1(16,i),XYZ1(15,i)]);
            CH1(11,i) = mean([XYZ1(6,i),XYZ1(17,i)]);
            CH1(12,i) = mean([XYZ1(18,i),XYZ1(7,i)]);
            CH1(13,i) = mean([XYZ1(8,i),XYZ1(19,i)]);
            CH1(14,i) = mean([XYZ1(20,i),XYZ1(9,i)]);
            CH1(15,i) = mean([XYZ1(10,i),XYZ1(21,i)]);
            CH1(16,i) = mean([XYZ1(22,i),XYZ1(11,i)]);
            CH1(17,i) = mean([XYZ1(12,i),XYZ1(23,i)]);
            CH1(18,i) = mean([XYZ1(24,i),XYZ1(13,i)]);
            CH1(19,i) = mean([XYZ1(14,i),XYZ1(25,i)]);
            CH1(20,i) = mean([XYZ1(26,i),XYZ1(15,i)]);
            CH1(21,i) = mean([XYZ1(16,i),XYZ1(27,i)]);
            CH1(22,i) = mean([XYZ1(18,i),XYZ1(17,i)]);
            CH1(23,i) = mean([XYZ1(18,i),XYZ1(19,i)]);
            CH1(24,i) = mean([XYZ1(20,i),XYZ1(19,i)]);
            CH1(25,i) = mean([XYZ1(20,i),XYZ1(21,i)]);
            CH1(26,i) = mean([XYZ1(22,i),XYZ1(21,i)]);
            CH1(27,i) = mean([XYZ1(22,i),XYZ1(23,i)]);
            CH1(28,i) = mean([XYZ1(24,i),XYZ1(23,i)]);
            CH1(29,i) = mean([XYZ1(24,i),XYZ1(25,i)]);
            CH1(30,i) = mean([XYZ1(26,i),XYZ1(25,i)]);
            CH1(31,i) = mean([XYZ1(26,i),XYZ1(27,i)]);
            CH1(32,i) = mean([XYZ1(28,i),XYZ1(17,i)]);
            CH1(33,i) = mean([XYZ1(18,i),XYZ1(29,i)]);
            CH1(34,i) = mean([XYZ1(30,i),XYZ1(19,i)]);
            CH1(35,i) = mean([XYZ1(20,i),XYZ1(31,i)]);
            CH1(36,i) = mean([XYZ1(32,i),XYZ1(21,i)]);
            CH1(37,i) = mean([XYZ1(22,i),XYZ1(33,i)]);
            CH1(38,i) = mean([XYZ1(34,i),XYZ1(23,i)]);
            CH1(39,i) = mean([XYZ1(24,i),XYZ1(35,i)]);
            CH1(40,i) = mean([XYZ1(36,i),XYZ1(25,i)]);
            CH1(41,i) = mean([XYZ1(26,i),XYZ1(37,i)]);
            CH1(42,i) = mean([XYZ1(38,i),XYZ1(27,i)]);
            CH1(43,i) = mean([XYZ1(28,i),XYZ1(29,i)]);
            CH1(44,i) = mean([XYZ1(30,i),XYZ1(29,i)]);
            CH1(45,i) = mean([XYZ1(30,i),XYZ1(31,i)]);
            CH1(46,i) = mean([XYZ1(32,i),XYZ1(31,i)]);
            CH1(47,i) = mean([XYZ1(32,i),XYZ1(33,i)]);
            CH1(48,i) = mean([XYZ1(34,i),XYZ1(33,i)]);
            CH1(49,i) = mean([XYZ1(34,i),XYZ1(35,i)]);
            CH1(50,i) = mean([XYZ1(36,i),XYZ1(35,i)]);
            CH1(51,i) = mean([XYZ1(36,i),XYZ1(37,i)]);
            CH1(52,i) = mean([XYZ1(38,i),XYZ1(37,i)]);
        end
        
        CH2 = zeros(52,3); % Others file 2
        for i = 1:3
            CH2(1,i) = mean([XYZ2(6,i),XYZ2(7,i)]);
            CH2(2,i) = mean([XYZ2(8,i),XYZ2(7,i)]);
            CH2(3,i) = mean([XYZ2(8,i),XYZ2(9,i)]);
            CH2(4,i) = mean([XYZ2(10,i),XYZ2(9,i)]);
            CH2(5,i) = mean([XYZ2(10,i),XYZ2(11,i)]);
            CH2(6,i) = mean([XYZ2(12,i),XYZ2(11,i)]);
            CH2(7,i) = mean([XYZ2(12,i),XYZ2(13,i)]);
            CH2(8,i) = mean([XYZ2(14,i),XYZ2(13,i)]);
            CH2(9,i) = mean([XYZ2(14,i),XYZ2(15,i)]);
            CH2(10,i) = mean([XYZ2(16,i),XYZ2(15,i)]);
            CH2(11,i) = mean([XYZ2(6,i),XYZ2(17,i)]);
            CH2(12,i) = mean([XYZ2(18,i),XYZ2(7,i)]);
            CH2(13,i) = mean([XYZ2(8,i),XYZ2(19,i)]);
            CH2(14,i) = mean([XYZ2(20,i),XYZ2(9,i)]);
            CH2(15,i) = mean([XYZ2(10,i),XYZ2(21,i)]);
            CH2(16,i) = mean([XYZ2(22,i),XYZ2(11,i)]);
            CH2(17,i) = mean([XYZ2(12,i),XYZ2(23,i)]);
            CH2(18,i) = mean([XYZ2(24,i),XYZ2(13,i)]);
            CH2(19,i) = mean([XYZ2(14,i),XYZ2(25,i)]);
            CH2(20,i) = mean([XYZ2(26,i),XYZ2(15,i)]);
            CH2(21,i) = mean([XYZ2(16,i),XYZ2(27,i)]);
            CH2(22,i) = mean([XYZ2(18,i),XYZ2(17,i)]);
            CH2(23,i) = mean([XYZ2(18,i),XYZ2(19,i)]);
            CH2(24,i) = mean([XYZ2(20,i),XYZ2(19,i)]);
            CH2(25,i) = mean([XYZ2(20,i),XYZ2(21,i)]);
            CH2(26,i) = mean([XYZ2(22,i),XYZ2(21,i)]);
            CH2(27,i) = mean([XYZ2(22,i),XYZ2(23,i)]);
            CH2(28,i) = mean([XYZ2(24,i),XYZ2(23,i)]);
            CH2(29,i) = mean([XYZ2(24,i),XYZ2(25,i)]);
            CH2(30,i) = mean([XYZ2(26,i),XYZ2(25,i)]);
            CH2(31,i) = mean([XYZ2(26,i),XYZ2(27,i)]);
            CH2(32,i) = mean([XYZ2(28,i),XYZ2(17,i)]);
            CH2(33,i) = mean([XYZ2(18,i),XYZ2(29,i)]);
            CH2(34,i) = mean([XYZ2(30,i),XYZ2(19,i)]);
            CH2(35,i) = mean([XYZ2(20,i),XYZ2(31,i)]);
            CH2(36,i) = mean([XYZ2(32,i),XYZ2(21,i)]);
            CH2(37,i) = mean([XYZ2(22,i),XYZ2(33,i)]);
            CH2(38,i) = mean([XYZ2(34,i),XYZ2(23,i)]);
            CH2(39,i) = mean([XYZ2(24,i),XYZ2(35,i)]);
            CH2(40,i) = mean([XYZ2(36,i),XYZ2(25,i)]);
            CH2(41,i) = mean([XYZ2(26,i),XYZ2(37,i)]);
            CH2(42,i) = mean([XYZ2(38,i),XYZ2(27,i)]);
            CH2(43,i) = mean([XYZ2(28,i),XYZ2(29,i)]);
            CH2(44,i) = mean([XYZ2(30,i),XYZ2(29,i)]);
            CH2(45,i) = mean([XYZ2(30,i),XYZ2(31,i)]);
            CH2(46,i) = mean([XYZ2(32,i),XYZ2(31,i)]);
            CH2(47,i) = mean([XYZ2(32,i),XYZ2(33,i)]);
            CH2(48,i) = mean([XYZ2(34,i),XYZ2(33,i)]);
            CH2(49,i) = mean([XYZ2(34,i),XYZ2(35,i)]);
            CH2(50,i) = mean([XYZ2(36,i),XYZ2(35,i)]);
            CH2(51,i) = mean([XYZ2(36,i),XYZ2(37,i)]);
            CH2(52,i) = mean([XYZ2(38,i),XYZ2(37,i)]);
        end
        
        CH = zeros(52,3); % Others file average
        for i = 1:3
            CH(1,i) = mean([CH1(1,i),CH2(1,i)]);
            CH(2,i) = mean([CH1(2,i),CH2(2,i)]);
            CH(3,i) = mean([CH1(3,i),CH2(3,i)]);
            CH(4,i) = mean([CH1(4,i),CH2(4,i)]);
            CH(5,i) = mean([CH1(5,i),CH2(5,i)]);
            CH(6,i) = mean([CH1(6,i),CH2(6,i)]);
            CH(7,i) = mean([CH1(7,i),CH2(7,i)]);
            CH(8,i) = mean([CH1(8,i),CH2(8,i)]);
            CH(9,i) = mean([CH1(9,i),CH2(9,i)]);
            CH(10,i) = mean([CH1(10,i),CH2(10,i)]);
            CH(11,i) = mean([CH1(11,i),CH2(11,i)]);
            CH(12,i) = mean([CH1(12,i),CH2(12,i)]);
            CH(13,i) = mean([CH1(13,i),CH2(13,i)]);
            CH(14,i) = mean([CH1(14,i),CH2(14,i)]);
            CH(15,i) = mean([CH1(15,i),CH2(15,i)]);
            CH(16,i) = mean([CH1(16,i),CH2(16,i)]);
            CH(17,i) = mean([CH1(17,i),CH2(17,i)]);
            CH(18,i) = mean([CH1(18,i),CH2(18,i)]);
            CH(19,i) = mean([CH1(19,i),CH2(19,i)]);
            CH(20,i) = mean([CH1(20,i),CH2(20,i)]);
            CH(21,i) = mean([CH1(21,i),CH2(21,i)]);
            CH(22,i) = mean([CH1(22,i),CH2(22,i)]);
            CH(23,i) = mean([CH1(23,i),CH2(23,i)]);
            CH(24,i) = mean([CH1(24,i),CH2(24,i)]);
            CH(25,i) = mean([CH1(25,i),CH2(25,i)]);
            CH(26,i) = mean([CH1(26,i),CH2(26,i)]);
            CH(27,i) = mean([CH1(27,i),CH2(27,i)]);
            CH(28,i) = mean([CH1(28,i),CH2(28,i)]);
            CH(29,i) = mean([CH1(29,i),CH2(29,i)]);
            CH(30,i) = mean([CH1(30,i),CH2(30,i)]);
            CH(31,i) = mean([CH1(31,i),CH2(31,i)]);
            CH(32,i) = mean([CH1(32,i),CH2(32,i)]);
            CH(33,i) = mean([CH1(33,i),CH2(33,i)]);
            CH(34,i) = mean([CH1(34,i),CH2(34,i)]);
            CH(35,i) = mean([CH1(35,i),CH2(35,i)]);
            CH(36,i) = mean([CH1(36,i),CH2(36,i)]);
            CH(37,i) = mean([CH1(37,i),CH2(37,i)]);
            CH(38,i) = mean([CH1(38,i),CH2(38,i)]);
            CH(39,i) = mean([CH1(39,i),CH2(39,i)]);
            CH(40,i) = mean([CH1(40,i),CH2(40,i)]);
            CH(41,i) = mean([CH1(41,i),CH2(41,i)]);
            CH(42,i) = mean([CH1(42,i),CH2(43,i)]);
            CH(43,i) = mean([CH1(43,i),CH2(43,i)]);
            CH(44,i) = mean([CH1(44,i),CH2(44,i)]);
            CH(45,i) = mean([CH1(45,i),CH2(45,i)]);
            CH(46,i) = mean([CH1(46,i),CH2(46,i)]);
            CH(47,i) = mean([CH1(47,i),CH2(47,i)]);
            CH(48,i) = mean([CH1(48,i),CH2(48,i)]);
            CH(49,i) = mean([CH1(49,i),CH2(49,i)]);
            CH(50,i) = mean([CH1(50,i),CH2(50,i)]);
            CH(51,i) = mean([CH1(51,i),CH2(51,i)]);
            CH(52,i) = mean([CH1(52,i),CH2(52,i)]);
        end
        
        % Format channel information
        CH=num2cell(CH);
        optodeArray=num2cell(optodeArray);
        
        SDX=vertcat(optodeArray{:,1});
        SDY=vertcat(optodeArray{:,2});
        SDZ=vertcat(optodeArray{:,3});
        CHX=vertcat(CH{:,1});
        CHY=vertcat(CH{:,2});
        CHZ=vertcat(CH{:,3});
        
        optode_positions(:,2)=[SDX;CHX];
        optode_positions(:,3)=[SDY;CHY];
        optode_positions(:,4)=[SDZ;CHZ];
        
        optode_positions=num2cell(optode_positions);
        
        % Create optode and channel labels
        SDCH = {'S11';'D11';'S12';'D12';'S13';'D13';'S14';'D14';
            'S15';'D15';'S16';'D16';'S17';'D17';'S18';'D18';'S19';
            'D21';'S21';'D22';'S22';'D23';'S23';'D24';'S24';'D25';
            'S25';'D26';'S26';'D27';'S27';'D28';'S28';'CH01';
            'CH02';'CH03';'CH04';'CH05';'CH06';'CH07';'CH08';
            'CH09';'CH10';'CH11';'CH12';'CH13';'CH14';'CH15';
            'CH16';'CH17';'CH18';'CH19';'CH20';'CH21';'CH22';
            'CH23';'CH24';'CH25';'CH26';'CH27';'CH28';'CH29';
            'CH30';'CH31';'CH32';'CH33';'CH34';'CH35';'CH36';
            'CH37';'CH38';'CH39';'CH40';'CH41';'CH42';'CH43';
            'CH44';'CH45';'CH46';'CH47';'CH48';'CH49';'CH50';
            'CH51';'CH52'};
        
        % Add labels
        optode_positions(:,1)=SDCH;
        
        % Generate averaged others file
        othersfile = [pathname, ParticipantID, '_others.csv'];
        
        % Print channel and label information to file
        fid = fopen(othersfile, 'wt');
        for i=1:size(optode_positions,1);
            fprintf(fid, '%s,%f,%f,%f\n', optode_positions{i,:});
        end
        fclose(fid);
        
        % Delete unnecessary files
        delete(othersfile1)
        delete(othersfile2)
        
    end
    
    if (file_output >= 3)
        %% File output for SPM-fNIRS (SPM12) - (origin/reference) - all probe arrays
        
        % Modify origin file for SPM-fNIRS (SPM12)
        % Open averaged origin file
        filename = ('originfile');
        delimiter = ',';
        formatSpec = '%s%s%s%s%[^\n\r]';
        fileID = fopen(originfile,'r');
        referenceArray = textscan(fileID, formatSpec, 'Delimiter', delimiter,  'ReturnOnError', false);
        fclose(fileID);
        
        % Allocate imported array to column variable names
        Label = referenceArray{:, 1};
        X = referenceArray{:, 2};
        Y = referenceArray{:, 3};
        Z = referenceArray{:, 4};
        
        % Replace the origin label information
        Reference = {'Reference';'NzHS';'IzHS';'ARHS';'ALHS';'Fp1HS';
            'Fp2HS';'FzHS';'F3HS';'F4HS';'F7HS';'F8HS';'CzHS';'C3HS';
            'C4HS';'T3HS';'T4HS';'PzHS';'P3HS';'P4HS';'T5HS';'T6HS';
            'O1HS';'O2HS'};
        
        % Combine all cell arrays
        reference_positions(:,1)=vertcat(Reference);
        reference_positions(:,2)=vertcat(X);
        reference_positions(1,2)={'X'};
        reference_positions(:,3)=vertcat(Y);
        reference_positions(1,3)={'Y'};
        reference_positions(:,4)=vertcat(Z);
        reference_positions(1,4)={'Z'};
        

        % Save the origin information arrays as comma separated values for
        % SPM-fNIRS (SPM12).  Format: 'reference_positions.csv'
        referencefile = [pathname, 'reference', '_positions.csv'];
        fid = fopen(referencefile, 'wt');
        for i=1:size(reference_positions,1)
            fprintf(fid, '%s, %s, %s, %s\n', reference_positions{i,:});
        end
        fclose(fid);
        
        %% File output for SPM-fNIRS (SPM12) - (others/optode) - all probe arrays)
        
        % Modify others file for SPM-fNIRS (SPM12)
        % Open averaged others file
        delimiter = ',';
        formatSpec = '%s%s%s%s%[^\n\r]';
        fileID = fopen(othersfile,'r');
        optodeArray = textscan(fileID, formatSpec, 'Delimiter', delimiter,  'ReturnOnError', false);
        fclose(fileID);
        
        % Allocate imported array to column variable names
        Optode = optodeArray{:, 1};
        X = optodeArray{:, 2};
        Y = optodeArray{:, 3};
        Z = optodeArray{:, 4};
        
        % Replace the others label information
        Oheader={'Optode'};
        Xheader={'X'};
        Yheader={'Y'};
        Zheader={'Z'};
        
        % Combine all cell arrays
        clear optode_positions
        optode_positions(:,1)=vertcat(Oheader,Optode);
        optode_positions(:,2)=vertcat(Xheader,X);
        optode_positions(:,3)=vertcat(Yheader,Y);
        optode_positions(:,4)=vertcat(Zheader,Z);
  
        % Save the others file information arrays as comma separated values
        % fro SPM-fNIRS (SPM12).  Format: 'optode_positions.csv'
        optodefile = [pathname, 'optode', '_positions.csv'];
        fid = fopen(optodefile, 'wt');
        for i=1:size(optode_positions,1)
            fprintf(fid, '%s, %s, %s, %s\n', optode_positions{i,:});
        end
        fclose(fid);
        
        %% Copy channel configuration files to the POS path
        % Depending on how you are processing you spatial registration
        % data, the SPM-fNIRS toolbox sometimes requires the refernce,
        % optode, and channel configuration files.  But, you may get an
        % error if these files are not all in the same folder.  This copies
        % them directly to the same path as all of the other files.  This
        % should save you some time and trouble later.
        
        % 3x3 x2 probe array
        if probe_array == 2
            scriptpath = fileparts(which('pos2spm')); % Find the script path
            configtxtfile = [scriptpath, '/ch_config/3x3x2_ch_config/ch_config.txt']; % Find the TXT file
            configcsvfile = [scriptpath, '/ch_config/3x3x2_ch_config/ch_config.csv']; % Find the CSV file
            copyfile(configtxtfile,pathname)
            copyfile(configcsvfile,pathname)
            clear scriptpath configtxtfile configcsvfile
        end
        
        % 3x5 x2 probe array
        if probe_array == 3
            scriptpath = fileparts(which('pos2spm')); % Find the script path
            configtxtfile = [scriptpath, '/ch_config/3x5x2_ch_config/ch_config.txt']; % Find the TXT file
            configcsvfile = [scriptpath, '/ch_config/3x5x2_ch_config/ch_config.csv']; % Find the CSV file
            copyfile(configtxtfile,pathname)
            copyfile(configcsvfile,pathname)
            clear scriptpath configtxtfile configcsvfile
        end
        
        % 3x11 x1 probe array
        if probe_array == 4
            scriptpath = fileparts(which('pos2spm')); % Find the script path
            configtxtfile = [scriptpath, '/ch_config/3x11x1_ch_config/ch_config.txt']; % Find the TXT file
            configcsvfile = [scriptpath, '/ch_config/3x11x1_ch_config/ch_config.csv']; % Find the CSV file
            copyfile(configtxtfile,pathname)
            copyfile(configcsvfile,pathname)
            clear scriptpath configtxtfile configcsvfile
        end
    end
    
    %% Move files to "Polhemus" folder one directory level up from the pathname
    
    % If a folder labeled "Polhemus" already exists, continue to move
    % files.  If a foldered labeled "Polhemus" does not exist, make the
    % folder before moving files.
    DIRCHECK = exist([pathname,'../Polhemus'], 'dir');
    if DIRCHECK == 0
        mkdir([pathname, '../Polhemus'])
    end
    
    % Move files
    if file_output == 2
        movefile(originfile, [pathname, '../Polhemus'])
        movefile(othersfile, [pathname, '../Polhemus'])
    end
    if file_output == 3
        movefile(referencefile, [pathname, '../Polhemus'])
        movefile(optodefile, [pathname, '../Polhemus'])
        movefile([pathname, '/ch_config.csv'], [pathname, '../Polhemus'])
        movefile([pathname, '/ch_config.txt'], [pathname, '../Polhemus'])
        delete(originfile)
        delete(othersfile)
    end
    if file_output == 4
        movefile(originfile, [pathname, '../Polhemus'])
        movefile(othersfile, [pathname, '../Polhemus'])
        movefile(referencefile, [pathname, '../Polhemus'])
        movefile(optodefile, [pathname, '../Polhemus'])
        movefile([pathname, '/ch_config.csv'], [pathname, '../Polhemus'])
        movefile([pathname, '/ch_config.txt'], [pathname, '../Polhemus'])
    end
    
    %% Message: Finished
    if file_output == 2
        helpdlg({'You have successfully generated all of the appropriately formated files necessary for spatial registration in NIRS_SPM.'; ''; 'Press "OK" or close to end.'}, 'pos2spm')
    end
    if file_output == 3
        helpdlg({'You have successfully generated all of the appropriately formated files necessary for spatial registration in the spm_fnirs toolbox.'; ''; 'Press "OK" or close to end.'}, 'pos2spm')
    end
    if file_output == 4
        helpdlg({'You have successfully generated all of the appropriately formated files necessary for spatial registration in NIRS_SPM and the spm_fnirs toolbox.'; ''; 'Press "OK" or close to end.'}, 'pos2spm')
    end
end

%% End: Clear all
clear all
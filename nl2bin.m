function nl2bin(date, sessions, Sherlock)
% IL created 4/10/19
%
% Inputs:
% -------
% date : string
%   date of session in format YYYY-MM-DD
% sessions : cell array
%   times of sessions as strings (from cheetah file names)
% Sherlock : bool
%   set to true if running on Sherlock; default is false
%
% Outputs:
% --------
% bin files for each session, plus a combined bin file of all sessions
% files will be saved in targetdir

% check input vars
if nargin == 2
    Sherlock = false;
end
sessions = string(sessions);

% set path
if Sherlock
    sourcedir ='/oak/stanford/groups/giocomo/export/data/Projects/RandomForage_NPandH3/Marrakech/VR/';
    targetdir = '/oak/stanford/groups/giocomo/export/data/Projects/RandomForage_NPandH3/Marrakech/ProcessedData/';
else
    sourcedir = 'Z:/giocomo/export/data/Projects/RandomForage_NPandH3/Marrakech/VR/';
    targetdir = 'Z:/giocomo/export/data/Projects/RandomForage_NPandH3/Marrakech/ProcessedData/'; 
end

% get bin file for each session
numSessions = length(sessions);
flist = {};
for s = 1:numSessions
    fprintf(['\nProcessing session ', num2str(s), ' out of ', num2str(numSessions), '\n'])
    dir = strcat(sourcedir, date, sessions{s});
    if s == 1
        if Sherlock
            file = neuralynx2kilosortSherlock(dir, strcat(targetdir, date));
        else
            file = neuralynx2kilosort(dir, strcat(targetdir, date));
        end
    end
    flist{s} = strcat(targetdir, date, '/', file);
end

% concatenate bin files
fid_write = fopen(fullfile(targetdir, date, [date '_dataMatrix.bin']), 'w');
for j = 1:length(flist)
    fid_read = fopen(flist{j});
    A = fread(fid_read, '*int16');
    fwrite(fid_write, A, 'int16')
    fclose(fid_read)
end
fclose(fid_write) 


end
addpath('/home/users/ilow/SiliconProbeCode')
addpath('/home/users/ilow/SiliconProbeCode/releaseDec2015/binaries')
addpath('/home/users/ilow/SiliconProbeCode/MatlabImportExport_v6.0.0')
addpath('/home/users/ilow/SiliconProbeCode/IL_Sherlock')
%%  
% Sherlock
% sourcedir ='/oak/stanford/groups/giocomo/export/data/Projects/RandomForage_NPandH3/Marrakech/VR/';
% targetdir = '/oak/stanford/groups/giocomo/export/data/Projects/RandomForage_NPandH3/Marrakech/ProcessedData/';

% local machine
sourcedir = 'Y:/giocomo/export/data/Projects/RandomForage_NPandH3/Marrakech/VR/';
targetdir = 'Y:/giocomo/export/data/Projects/RandomForage_NPandH3/Marrakech/ProcessedData/';

dates = {'2019-03-30' '2019-03-31' '2019-04-02' '2019-04-03' '2019-04-01'};
sessions = {'_11-56-49' '_17-19-05' '_18-04-55' '_18-51-41' '_19-44-24'...
    '_14-21-23' '_15-05-42' '_16-04-42' '_14-50-59' '_16-20-51'};

dir1 = {strcat(sourcedir, dates{3}, sessions{3})};
dir2 = {strcat(sourcedir, dates{3}, sessions{4})};
dir3 = {strcat(sourcedir, dates{3}, sessions{5})};
    
% neuralynx2kilosortSherlock(dir1, strcat(targetdir, dates{3}))
neuralynx2kilosortSherlock(dir2, strcat(targetdir, dates{3}))
neuralynx2kilosortSherlock(dir3, strcat(targetdir, dates{3}))

flist = {'[]' '[]' '[]'};
for i = 3:5
    file = strcat(targetdir, dates{3}, '/', dates{3}, sessions{3}, '_dataMatrix.bin');
    flist{i - 2} = file;
end
flist = string(flist);

% to reduce memory usage, update the matrix in pieces:
date = dates{3};
fid_write = fopen(fullfile(targetdir, date, [date '_dataMatrix.bin']), 'w');
for j = 1:length(flist)
    fid_read = fopen(flist{j});
    A = fread(fid_read, '*int16');
    fwrite(fid_write, A, 'int16')
    fclose(fid_read);
end
fclose(fid_write);
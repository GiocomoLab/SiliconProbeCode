addpath('/home/users/ilow/SiliconProbeCode')
addpath('/home/users/ilow/SiliconProbeCode/releaseDec2015/binaries')
addpath('/home/users/ilow/SiliconProbeCode/MatlabImportExport_v6.0.0')
addpath('/home/users/ilow/SiliconProbeCode/IL_Sherlock')
%%  
% Sherlock
sourcedir ='/oak/stanford/groups/giocomo/export/data/Projects/RandomForage_NPandH3/Marrakech/VR/';
targetdir = '/oak/stanford/groups/giocomo/export/data/Projects/RandomForage_NPandH3/Marrakech/ProcessedData/';

% local machine
% sourcedir = 'Z:/giocomo/export/data/Projects/RandomForage_NPandH3/Marrakech/VR/';
% targetdir = 'Z:/giocomo/export/data/Projects/RandomForage_NPandH3/Marrakech/ProcessedData/';

dates = {'2019-03-30' '2019-03-31' '2019-04-02' '2019-04-03' '2019-04-01'};
sessions = {'_11-56-49' '_17-19-05' '_18-04-55' '_18-51-41' '_19-44-24'...
    '_14-21-23' '_15-05-42' '_16-04-42' '_14-50-59' '_16-20-51'};

dir1 = {strcat(sourcedir, dates{1}, sessions{1})};
neuralynx2kilosortSherlock(dir1, strcat(targetdir, dates{1}))

% dir2 = {strcat(sourcedir, dates{2}, sessions{2})};
% neuralynx2kilosortSherlock(dir2, strcat(targetdir, dates{2}))
% 
% dir3 = {'[]' '[]' '[]'};
% for i = 3:5
%     dir3{i - 2} = {strcat(sourcedir, dates{3}, sessions{i})};
% end
% neuralynx2kilosortSherlock(dir3, strcat(targetdir, dates{3}))
% 
% dir4 = {'[]' '[]' '[]'};
% for i = 6:8
%     dir4{i - 5} = {strcat(sourcedir, dates{4}, sessions{i})};
% end
% neuralynx2kilosortSherlock(dir4, strcat(targetdir, dates{4}))
% 
% dir5 = {'[]' '[]'};
% for i = 9:10
%     dir5{i - 8} = {strcat(sourcedir, dates{5}, sessions{i})};
% end
% neuralynx2kilosortSherlock(dir5, strcat(targetdir, dates{5}))
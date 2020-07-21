%% compute and save post offset
function offset = get_post_offset(file_path, mouse, session)

% get session params
% mouse = 'Pisa'; % or supply this
% session = '0430_1'; % or supply this
date = split(session, '_');
date = date{1};

% define paths
addpath(genpath('C:\code\spikes'));
addpath(genpath('C:\code\npy-matlab'));
% file_path = 'Z:\giocomo\export\data\Projects\RandomForage_NPandH3\'; % or supply this
main_name = strcat(mouse, '_', date, '_g0');
data_dir = fullfile(file_path, 'ProcessedData', mouse, main_name);

% define files
NIDAQ_file = fullfile(data_dir, strcat(main_name, '_t0.nidq.bin'));
NIDAQ_config = fullfile(data_dir, strcat(main_name, '_t0.nidq.meta'));

%% Get NIDAQ data
% get the nidaq sample rate & get number of recorded nidaq channels
dat = textscan(fopen(NIDAQ_config), '%s %s', 'Delimiter', '=');
names = dat{1};
vals = dat{2};
loc = contains(names, 'niSampRate');
sync_sampling_rate = str2double(vals{loc});
loc2 = contains(names, 'nSavedChans');
n_channels_nidaq = str2double(vals{loc2});

% get neuropixels sync pulse times and convert to seconds
fpNIDAQ = fopen(NIDAQ_file);
datNIDAQ = fread(fpNIDAQ,[n_channels_nidaq,Inf], '*int16');
fclose(fpNIDAQ);
syncDat = datNIDAQ(2,:) > 1000;
frame_times_np = find(abs(diff(syncDat)) == 1) + 1;
frame_times_np = frame_times_np / sync_sampling_rate;

%% Save offset to data struct
offset = frame_times_np(1);
data_file = strcat(mouse, '_', session, '_offset.mat');
save(fullfile(data_dir, data_file), 'offset')
end






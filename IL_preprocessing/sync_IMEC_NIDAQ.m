function sync_IMEC_NIDAQ(data_dir, main_name, mouse, session)

%function sync_vr_to_np(data_dir)
addpath(genpath('F:\code\spikes'));
addpath(genpath('F:\code\npy-matlab'));

% define file paths/key variables
% root = 'Z:\giocomo\export\data\Projects\RandomForage_NPandH3\ProcessedData\';
% data_dir = strcat(root, 'Vancouver_1118_g0\');
% main_name = 'Vancouver_1118_g0';
% mouse = 'Vancouver';
% session = '1118_1';

% define files
NIDAQ_file = strcat(data_dir, main_name, '_t0.nidq.bin');
NIDAQ_config = strcat(data_dir, main_name,'_t0.nidq.meta');
spike_dir = strcat(data_dir, main_name,'_imec0');

%% load spiking data
load(strcat(data_dir, mouse, '_', session, '_data.mat'))
sp = data.sp;

%% Get NIDAQ Data
%get the nidaq sample rate & get number of recorded nidaq channels
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

%% CORRECT FOR DRIFT BETWEEN IMEC AND NIDAQ BOARDS
% TWO-PART CORRECTION
% 1. Get sync pulse times relative to NIDAQ and Imec boards.  
% 2. Quantify difference between the two sync pulse times and correct in
% spike.st. 
%
% PART 1: GET SYNC TIMES RELATIVE TO EACH BOARD
% We already loaded most of the NIDAQ data above. Here, we access the sync
% pulses used to sync Imec and NIDAQ boards together. The times a pulse is
% emitted and registered by the NIDAQ board are stored in syncDatNIDAQ below.
syncDatNIDAQ=datNIDAQ(1,:)>1000;

% convert NIDAQ sync data into time data by dividing by the sampling rate
ts_NIDAQ = strfind(syncDatNIDAQ,[0 1])/sync_sampling_rate; 
% ts_NIDAQ: these are the sync pulse times relative to the NIDAQ board

% Now, we do the same, but from the perspective of the Imec board. 
if exist(spike_dir, 'dir')
    LFP_config = strcat(spike_dir, '\', main_name, '_t0.imec0.lf.meta');
    LFP_file = strcat(spike_dir, '\', main_name, '_t0.imec0.lf.bin');
else
    spike_dir = strcat(data_dir, main_name,'_imec');
    if exist(spike_dir, 'dir')
        LFP_config = strcat(spike_dir, '\', main_name, '_t0.imec0.lf.meta');
        LFP_file = strcat(spike_dir, '\', main_name, '_t0.imec0.lf.bin');
    else
        LFP_config = strcat(data_dir, main_name, '_t0.imec0.lf.meta');
        LFP_file = strcat(data_dir, main_name, '_t0.imec0.lf.bin');
    end
end
dat=textscan(fopen(LFP_config),'%s %s','Delimiter','=');
names=dat{1};
vals=dat{2};
loc=contains(names,'imSampRate');
lfp_sampling_rate=str2double(vals{loc});
% for loading only a portion of the LFP data
fpLFP = fopen(LFP_file);
fseek(fpLFP, 0, 'eof'); % go to end of file
fpLFP_size = ftell(fpLFP); % report size of file
fpLFP_size = fpLFP_size/(2*384); 
fclose(fpLFP);
% get the sync pulse times relative to the Imec board
fpLFP=fopen(LFP_file);
fseek(fpLFP,384*2,0);
ftell(fpLFP);
datLFP=fread(fpLFP,[1,round(fpLFP_size/4)],'*int16',384*2); % this step used to take forever
fclose(fpLFP);
syncDatLFP=datLFP(1,:)>10; 
ts_LFP = strfind(syncDatLFP,[0 1])/lfp_sampling_rate;
% ts_LFP: these are the sync pulse times relative to the Imec board


%% PART 2: TIME CORRECTION
lfpNIDAQdif = ts_LFP - ts_NIDAQ(1:size(ts_LFP, 2)); % calculate the difference between the sync pulse times
fit = polyfit(ts_LFP, lfpNIDAQdif, 1); % linear fit 
correction_slope = fit(1); % this is the amount of drift we get per pulse (that is, per second)
% save the old, uncorrected data as sp.st_uncorrected
sp.st_uncorrected = sp.st; % save uncorrected spike times (st)

% save the new, corrected spike times
st_corrected = sp.st - sp.st * correction_slope; % in two steps to avoid confusion
sp.st = st_corrected; % overwrite the old sp.st
data.sp = sp; % overwrite the old data.sp

%% Re-Save Data Struct
save_dir = 'F:\ilow\sync_data\';
save(strcat(save_dir, mouse, '_', session, '_data.mat'), 'data')
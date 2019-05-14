%function sync_vr_to_np(data_dir)
addpath(genpath('F:\code\spikes'));
addpath(genpath('F:\code\npy-matlab'));


% define files
data_dir = 'F:\processed\Milan_0420';

main_name = '0420_2_g0';
mouse = 'Milan';
NIDAQ_file = fullfile(data_dir,strcat(main_name,'_t0.nidq.bin'));
NIDAQ_config = fullfile(data_dir,strcat(main_name,'_t0.nidq.meta'));
session = '0420_2';
spike_dir = fullfile(data_dir,strcat(main_name,'_imec0'));

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

frame_times_np = find(abs(diff(syncDat)) == 1) + 1;
frame_times_np = frame_times_np / sync_sampling_rate;


%% Get Unity Data
[posx, frame_times_vr] = getPositionData(session, root);
[rewardt, rewardcenters, rewardautomatic] = getRewardTimes(session, dir);
[lickx, lickt] = getLickData(session, dir);


%% Synchronize Unity to NIDAQ
% set vr frame times to be the time of neuropixels pulses
% make sure the number of frames matches (can be off by one because of
% odd/even numbers of frames)
if abs(numel(frame_times_np) - numel(frame_times_vr)) <= 1
    idx=1:min(numel(frame_times_np),numel(frame_times_vr)); %use shorter index
    post = frame_times_np(idx)';
    posx = posx(idx);
    
    % transform lick and reward times into neuropixels reference frame
    [~, ~, lick_idx] = histcounts(lickt, frame_times_vr);
    lickt = post(logical(lick_idx));
    [~, ~, reward_idx] = histcounts(rewardt, frame_times_vr);
    rewardt = post(logical(reward_idx));
else
    disp('ERROR: number of sync pulses does not match number of frames.')
end
% check alignment - points should fall approximately on unity line
figure
scatter(diff(post),diff(frame_times_vr(idx)),2,1:length(idx)-1)

%% Get Spike Data
% load spike times
sp = loadKSdir(spike_dir);

% dirty hack for when kilosort2 used wrong sampling rate
% st=sp.st;
% in_samples=st*32000;
% sp.st=in_samples/30000;

%% Clean Up and Align to Session Start/End
% shift everything to start at zero
offset = post(1);
post = post - offset;
lickt = lickt - offset;
rewardt = rewardt - offset;
sp.st = sp.st - offset;

% resample position to have constant time bins and deal with teleports
posx = interp1(post,posx,(0:0.02:max(post))');
vr_data_downsampled=interp1(post,vr_position_data,(0:0.02:max(post)));
post = (0:0.02:max(post))';
posx([false; diff(posx) < -2]) = round(posx([false;diff(posx) < -2]) / 400) * 400;

% compute trial number for each time bin
trial = [1; cumsum(diff(posx) < -100) + 1];
if round(posx(end), -1) == 400
    num_trials = max(trial);
else % stopped session mid-trial
    num_trials = max(trial) - 1;
end

% throw out bins after the last trial
keep = trial <= num_trials;
trial = trial(keep);
posx = posx(keep);
post = post(keep);

% throw out licks before and after session
keep = lickt > min(post) & lickt < max(post);
lickx = lickx(keep);
lickt = lickt(keep);

% throw out rewards before and after session
keep = rewardt > min(post) & rewardt < max(post);
rewardt = rewardt(keep);
rewardcenters = rewardcenters(keep);
rewardautomatic = rewardautomatic(keep);

% cut off all spikes before and after vr session
keep = sp.st >= 0 & sp.st <= post(end);
sp.st = sp.st(keep);
sp.spikeTemplates = sp.spikeTemplates(keep);
sp.clu = sp.clu(keep);
sp.tempScalingAmps = sp.tempScalingAmps(keep);

% save processed data
save(fullfile(data_dir,strcat(mouse,'_',session,'.mat')),'sp','post','posx','lickt','lickx','trial','trial_contrast','trial_gain');
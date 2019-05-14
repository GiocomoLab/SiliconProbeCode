%function sync_vr_to_np(data_dir)
addpath(genpath('C:\code\spikes'));
addpath(genpath('C:\code\npy-matlab'));


% path to folder with kilosort data, video, and VR data
data_dir = 'F:\J3\npJ3_0505_gain_g0';

% define files
[~,main_name]=fileparts(data_dir);
mouse = strsplit(main_name,'_');
mouse = mouse{1};
NIDAQ_file = fullfile(data_dir,strcat(main_name, '_t0.nidq.bin'));
NIDAQ_config = fullfile(data_dir,strcat(main_name, '_t0.nidq.meta'));
session = '0505_dark_1';
spike_dir = fullfile(data_dir, strcat(main_name, '_imec0'));
vid_dir = fullfile(data_dir, 'video');

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

% get video frame TTL times and convert to seconds
syncDat_2 = datNIDAQ(3,:) > 1000; % <-- CHECK THIS
vid_times_np = find(diff(syncDat_2) == 1) + 1;
vid_times_np = vid_times_np / sync_sampling_rate;

% check that video pulses came once every three syncing pulses
if sum(vid_times_np - frame_times_np(3:3:end)) > 1e-10
    disp('ERROR: video TTLs misaligned from sync TTLs')
end

%% Get Unity Data
[posx, frame_times_vr] = getPositionData(session, root);
[rewardt, rewardcenters, rewardautomatic] = getRewardTimes(session, dir);
[lickx, lickt] = getLickData(session, dir);

%% Get Video Data
load([vid_dir, session, '_framedata.mat'])
frame_times_vid = framedata.times;

%% Synchronize Unity to NIDAQ
% set vr frame times to be the time of neuropixels pulses
% make sure the number of frames matches (can be off by one because of
% odd/even numbers of frames)
if abs(numel(frame_times_np) - numel(frame_times_vr)) <= 1
    idx=1:min(numel(frame_times_np),numel(frame_times_vr)); %use shorter index
    post = frame_times_np(idx)';
    posx = posx(idx);
    
    % set video frame times to be time of every third pulse
    vid_idx = 3:3:(numel(frame_times_vid) * 3);
    framet = frame_times_np(vid_idx);
    % or linearly regress frame time on np time? see which looks better
%     cam_beta = [ones(size(frame_times_vid)) frame_times_vid] \ frame_times_np(vid_idx);
%     framet = [ones(size(frame_times_vid)) frame_times_vid] * cam_beta;
    
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
title('neuropixels TTL vs. unity frame time')
scatter(diff(post),diff(frame_times_vr(idx)),2,1:length(idx)-1)

figure
title('neuropixels TTL vs. camera frame time')
scatter(diff(framet),diff(frame_times_vid),2,1:length(idx)-1)

%% Get Spike Data
% load spike times
sp = loadKSdir(spike_dir);

% dirty hack for when kilosort2 used wrong sampling rate
% st=sp.st;
% in_samples=st*32000;
% sp.st=in_samples/30000;

%% Get Pupil and Whisk Data
% testvid_start is the index to find framet at start of 30s test video
[pupil, whisk, testvid_start] = analyzeFaceVideo(vid_dir, session, numel(framet));

%% Clean Up and Align to Session Start/End
% shift everything to start at zero
offset = post(1);
post = post - offset;
lickt = lickt - offset;
rewardt = rewardt - offset;
sp.st = sp.st - offset;
framet = framet - offset;

% resample position to have constant time bins and deal with teleports
posx = interp1(post,posx,(0:0.02:max(post))');
vr_data_downsampled=interp1(post,vr_position_data,(0:0.02:max(post)));
post = (0:0.02:max(post))';
posx([false; diff(posx) < -2]) = round(posx([false;diff(posx) < -2]) / 400) * 400;

% upsample pupil and whisk so we have a value for each post
pupil_upsampled = interp1(framet, pupil, post);
whisk_upsampled = interp1(framet, whisk, post);

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
pupil_upsampled = pupil_upsampled(keep);
whisk_upsampled = whisk_upsampled(keep);
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

% throw out video before and after session
keep = framet > min(post) & framet < max(post);
framet = framet(keep);
pupil = pupil(keep);
whisk = whisk(keep);

% cut off all spikes before and after vr session
keep = sp.st >= 0 & sp.st <= post(end);
sp.st = sp.st(keep);
sp.spikeTemplates = sp.spikeTemplates(keep);
sp.clu = sp.clu(keep);
sp.tempScalingAmps = sp.tempScalingAmps(keep);

%% Save Processed Data
save(fullfile(data_dir, strcat(mouse,'_',session,'.mat')),...
    'sp', 'post', 'posx', 'lickt', 'lickx', 'trial',...                                 % unity
    'rewardt', 'rewardcenters', 'rewardautomatic',...                                   % reward
    'framet', 'pupil', 'whisk', 'pupil_upsampled', 'whisk_upsampled', 'testvid_start'); % video
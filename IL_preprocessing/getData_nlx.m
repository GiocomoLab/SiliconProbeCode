function getData_nlx
% created by IL 4/12/19
clear all
close all
clc

fprintf(strcat('\nStart Time: ', datestr(now,'mmmm dd, yyyy HH:MM:SS AM'),'\n'))
% session params - update these!
mouse = 'Marrakech';
vr_sessions = ["0403_1", "0403_2", "0403_3"];
nlx_sessions = ["2019-04-03_14-21-23", "2019-04-03_15-05-42", "2019-04-03_16-04-42"];

% set paths and directories - may need to adjust
dir = 'Z:\giocomo\export\data\Projects\RandomForage_NPandH3\';
local_code = 'C:\Users\ilow\Desktop\Git_Repos\';
addpath([local_code '\spikes\preprocessing\phyHelpers']);
addpath([local_code '\npy-matlab\npy-matlab']);
addpath([local_code 'SiliconProbeCode\MatlabImportExport_v6.0.0'])
data_dir = fullfile(dir, mouse, '\ProcessedData\2019-04-03');

% load spike data
fprintf('\nloading spike data...')
sp = loadKSdir(data_dir);
max_t = 0;

% Get data for each session
for s = 1:length(vr_sessions)
    fprintf(['\n\nProcessing session ', num2str(s), ' of ', num2str(length(vr_sessions))])
    % synchronize unity, face cam, and neuralynx
    fprintf('\nsynchronizing recordings...')
    vr_session = vr_sessions{s};
    nlx_session = nlx_sessions{s};
    d = sync_vr_to_nlx_multiple_inputs(dir, mouse, vr_session, nlx_session);
%     framet = d.framet_sync;

    % Position and Time
    % -----------------
    fprintf('\ngetting behavioral data...')
    % each post starts at some non-zero value - correct to start at 0
    offset = d.post(1);
    post = d.post - offset;

    % resample position for constant time bins
    dt = 0.02;
    posx = interp1(post, d.posx, (0:dt:max(post))');
    post_raw = interp1(post, d.post_raw, (0:dt:max(post))');
    post = (0:dt:max(post))';

    % handle teleports
    posx([false; diff(posx) < -50]) = 0;
    
    % Licks and Rewards
    % -----------------
    % get lick data
    fid = fopen(fullfile(dir, mouse, strcat('\VR\', vr_session, '_licks.txt')),'r');
    vr_lick_data = fscanf(fid, '%f', [2,inf])';
    fclose(fid);
    lickx = vr_lick_data(:,1);
    lickt = vr_lick_data(:,2);

    % map lick time onto neuralynx time
    [~, ~, lick_idx] = histcounts(lickt, d.post_raw);
    lickt = post(logical(lick_idx));

    % get reward data
    [rewardt, rewardcenters, rewardautomatic] = getRewardTimes(mouse,vr_session,dir);
    [~, ~, reward_idx] = histcounts(rewardt, d.post_raw);
    rewardt = post(logical(reward_idx));


    % Pupil and Whisk
    % ---------------
%     vid_file = fullfile(dir, mouse, 'Video', strcat(vr_session,'.mp4'));
%     if exist(vid_file,'file')
%         % get index for frames within session
%         frame_idx = find(d.framet_sync <= max(post));
% 
%         % testvid_start is the index to find framet at start of 30s test video
%         [pupil, whisk, testvid_start] = analyzeFaceVideo(mouse, vr_session, frame_idx);
%     else
%         disp('video file not found')
%     end
    
    
    % Spikes
    % ------
    fprintf('\ngetting spike data...')
    % get spikes for this session
    min_t = max_t + offset;
    max_t = max_t + max(d.post);
    spikes = {}; % struct for this session's spike data
    
    % keep spikes from within this session
    keep = sp.st > min_t & sp.st <= max_t;
    spikes.st = sp.st(keep) - offset;
    spikes.spikeTemplates = sp.spikeTemplates(keep);
    spikes.clu = sp.clu(keep);
    spikes.tempScalingAmps = sp.tempScalingAmps(keep);
    
    
    
    % Save Data
    % ---------
    save(fullfile(data_dir, strcat(vr_session,'.mat')),...
        'spikes', 'post', 'posx', 'lickt', 'rewardt', 'rewardcenters',...
        'rewardautomatic')
end

fprintf(strcat('\nFinished: ', datestr(now,'mmmm dd, yyyy HH:MM:SS AM'),'\n'))
    
end
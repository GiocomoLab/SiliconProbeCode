% set paths and directories
data_dir = 'Z:\giocomo\export\data\Projects\RandomForage_NPandH3\';
mouse = 'Marrakech';
vr_session = '0403_1';
nlx_session = '2019-04-03_14-21-23';
d = {}; % struct to  hold data

% get frame timestamps from video
load([data_dir mouse '\Video\' vr_session '_framedata.mat'])
framet = framedata.times;
d.framet_raw = framet;

% get position and time data from VR
pos_file = [data_dir mouse '\VR\' vr_session '_position.txt'];
fid = fopen(pos_file);
vr_data = fscanf(fid,'%f',[2 Inf])';
d.posx = vr_data(:,1);
ttl_vr = vr_data(:,2);
fclose(fid);

%% extract TTLs from neuralynx file
eventsPath = [data_dir mouse '\VR\' nlx_session '\Events.nev'];
[ev_times, EventIDs, ttl_nlx, Header] = Nlx2MatEV(eventsPath, [1 1 1 0 0], 1, 1, [] );
ev_times = (ev_times - ev_times(1))/1000000; % start at zero, convert to seconds

% take only events between first and last pin up
keep_idx = find(ttl_nlx==1,1,'first'):find(ttl_nlx==1,1,'last');
ev_times = ev_times(keep_idx);
ttl_nlx = ttl_nlx(keep_idx);

% separate pulse trains for unity (1) vs. camera (2) TTLs
ttl_diff = diff(ttl_nlx);
ttl_diff = [ttl_nlx(1); ttl_diff];
ttl_unity = ev_times(abs(ttl_diff) == 1 | abs(ttl_diff) == 3);
ttl_cam = ev_times(ttl_diff == 1 | ttl_diff == 2 | ttl_diff == 3);

%% align data
% truncate to correct number of frames
idx_vrframes = 1:min(numel(ttl_unity), numel(ttl_vr));
d.post = ttl_unity(idx_vrframes)';

idx_vidframes = 1:min(numel(ttl_cam), numel(framet));
ttl_cam = ttl_cam(idx_vidframes);
framet = framet(idx_vidframes);

% check alignment
figure
plot(diff(d.post),diff(ttl_vr(idx_vrframes)),'.')

% sync face cam and neuralynx
if corr(ttl_cam, framet) < 0.999
    error('\nERROR: Something wrong with camera syncing (pulses not aligning)\n');
else
    % linearly regress camera time on nlx time to align and adjust for drift
    cam_beta = [ones(size(framet)) framet] \ ttl_cam;
    d.framet_sync = [ones(size(framet)) framet] * cam_beta;
end











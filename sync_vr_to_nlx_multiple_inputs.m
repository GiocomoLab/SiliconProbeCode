function d = sync_vr_to_nlx_multiple_inputs(data_dir, mouse, vr_session, nlx_session)

d = {}; % struct to  hold data

% get frame timestamps from face camera
load([data_dir mouse '\Video\' vr_session '_framedata.mat'])
framet = framedata.times;
d.framet_raw = framet;

% get position and time data from VR
pos_file = [data_dir mouse '\VR\' vr_session '_position.txt'];
fid = fopen(pos_file);
vr_data = fscanf(fid,'%f',[2 Inf])';
d.posx = vr_data(:,1);
ttl_vr = vr_data(:,2);
d.post_raw = ttl_vr;
if any(diff(d.post_raw) < 0)
    fprintf('\n checkpoint 1: decreasing time encountered')
end
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
ttl_diff = [ttl_nlx(1) ttl_diff];
ttl_unity = ev_times(abs(ttl_diff) == 1 | abs(ttl_diff) == 3);
% ttl_cam = ev_times(ttl_diff == 1 | ttl_diff == 2 | ttl_diff == 3);
if any(diff(ttl_unity) < 0)
    fprintf('\ndecreasing time encountered')
end

%% adjust for ground issues(?)
if numel(ttl_unity) - numel(ttl_vr) > 1
    fprintf('\nwarning! too many pulses recorded on neuralynx!')
    fprintf('\nadjusting to realign...\n')
    diff_unity = diff(ttl_unity);
%     [~, keep] = unique(round(ttl_unity, 2), 'last');
%     ttl_unity = ttl_unity(keep);    
    err_idx = find(abs(diff_unity) < 0.005); % interval too short
    ttl_unity(err_idx + 1) =[];
    if any(diff(ttl_unity) < 0)
        fprintf('\ndecreasing time encountered\n')
    end
    
%     diff_cam = diff(ttl_cam);
%     err_cam = find(round(diff_cam, 2) < 0.01); % interval too short
%     ttl_cam(err_cam + 1) =[];
    
    % truncate to correct number of frames
    idx_vrframes = 1:min(numel(ttl_unity), numel(ttl_vr));
    ttl_unity = ttl_unity(idx_vrframes)';
    ttl_vr = ttl_vr(idx_vrframes);
    diff_vr = diff(ttl_vr);
    
%     idx_vidframes = 1:min(numel(ttl_cam), numel(framet));
%     ttl_cam = ttl_cam(idx_vidframes);
%     framet = framet(idx_vidframes);
%     diff_framet = diff(framet);
    
    % correct for errors in heuristic
    err_idx2 = find(abs(diff(ttl_vr) - diff(ttl_unity)) > 0.001);
    for i = 1:length(err_idx2)
        ttl_unity(err_idx2(i) + 1) = ttl_unity(err_idx2(i)) + diff_vr(err_idx2(i));
    end
    
    % ensure all post values are unique
    [ttl_unity, u_idx] = unique(ttl_unity, 'last');
    ttl_vr = ttl_vr(u_idx);
    d.post = ttl_unity;
    if any(diff(d.post) < 0)
        fprintf('\n checkpoint 2: decreasing time encountered')
    end
%     ttl_cam = ttl_unity(3:3:end);
    
%     err_cam2 = find(abs(diff(framet) - diff(ttl_cam)) > 0.0001);
%     for i = 1:length(err_cam2)
%         ttl_cam(err_cam2(i) + 1) = ttl_cam(err_cam2(i)) + diff_framet(err_cam2(i));
%     end
else
    % truncate to correct number of frames
    idx_vrframes = 1:min(numel(ttl_unity), numel(ttl_vr));
    d.post = ttl_unity(idx_vrframes)';
    ttl_vr = ttl_vr(idx_vrframes);
%     
%     idx_vidframes = 1:min(numel(ttl_cam), numel(framet));
%     ttl_cam = ttl_cam(idx_vidframes);
%     framet = framet(idx_vidframes);
end

%% align data
d.posx = d.posx(idx_vrframes);
d.posx = d.posx(u_idx);
d.post_raw = d.post_raw(idx_vrframes);
if any(diff(d.post_raw) < 0)
    fprintf('\n checkpoint 3: decreasing time encountered\n')
end
d.post_raw = d.post_raw(u_idx);
if any(diff(d.post_raw) < 0)
    fprintf('\n checkpoint 4: decreasing time encountered\n')
end

% check alignment
figure(1)
title('unity frames')
plot(diff(ttl_unity),diff(ttl_vr),'.')

% ensure that all time vectors are increasing
if any(diff(d.post) < 0)
    idx = [1; find(diff(d.post) < 0) + 1];
    d.post = d.post(idx);
    d.posx = d.posx(idx);
    d.post_raw = d.post.raw(idx);
end
if any(diff(d.post) < 0)
    idx = [1; find(diff(d.post) < 0) + 1];
    d.post = d.post(idx);
    d.posx = d.posx(idx);
    d.post_raw = d.post.raw(idx);
end


% figure(2)
% title('camera frames')
% plot(diff(ttl_cam),diff(framet),'.')
% 
% % sync face cam and neuralynx
% if corr(ttl_cam', framet) < 0.999
%     error('\nERROR: Something wrong with camera syncing (pulses not aligning)\n');
% else
%     % linearly regress camera time on nlx time to align and adjust for drift
%     cam_beta = [ones(size(framet)) framet] \ ttl_cam;
%     d.framet_sync = [ones(size(framet)) framet] * cam_beta;
% end


end








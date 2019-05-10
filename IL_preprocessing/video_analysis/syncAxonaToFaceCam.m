function [v, post] = syncAxonaToFaceCam(mouse, session, p)
% syncs Axona/VR to face camera frame times

% IL created 7/18/18 based on syncAxonaToVR by MGC

baseFolder = p.WorkingDirectory{1};
data_file = [mouse '\Video\' session '_framedata.mat'];
v = {}; % struct to hold frame data


%%%%%%%%%%%%%%%%%%%%%%
% load timestamp info
%%%%%%%%%%%%%%%%%%%%%%

% get frame timestamps from camera
load([baseFolder data_file])
framet = framedata.times;
v.framet_raw = framet;

% get sync pulse timestamps from VR session
[~, pulse_times_vr] = getPositionData(mouse, session, p);
% pulse_times_vr = pulse_times_vr - min(pulse_times_vr); % make VR recording start at 0

% get digital input timestamps from Axona
inp_file_axona = strcat(baseFolder,mouse,'\VR\',session,'.inp');
[pulse_times_axona, pulse_type_axona, pulse_values_axona] = getinp(inp_file_axona);
pulse_times_axona = pulse_times_axona(pulse_type_axona=='I');
pulse_times_axona = pulse_times_axona(2:end);
pulse_times_axona = pulse_times_axona - min(pulse_times_axona); % make axona time start at 0
pulse_values_axona = pulse_values_axona(pulse_type_axona=='I');
pulse_values_axona = pulse_values_axona(2:end);

% separate pulse trains from axona inputs 1 (unity) and 4 (camera)
pulse_diff = diff(pulse_values_axona);
pulse_diff = [pulse_values_axona(1); pulse_diff];
pulse_times_unity =...
    pulse_times_axona(abs(pulse_diff) == 1 | abs(pulse_diff) == 5 | abs(pulse_diff) == 3);
pulse_times_faceCam =...
    pulse_times_axona(pulse_diff == 4 | pulse_diff == 5 | pulse_diff == 3);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% synchronize face cam to axona
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% truncate to correct number of pulses
num_frames = min(numel(framet), numel(pulse_times_faceCam));
framet = framet(1:num_frames);
pulse_times_faceCam = pulse_times_faceCam(1:num_frames);
v.num_frames = numel(pulse_times_faceCam);

% sync face cam and axona
if corr(pulse_times_faceCam, framet) < 0.999
    error('\nERROR: Something wrong with camera syncing (pulses not aligning)\n');
else
    % linearly regress camera time on axona time to align and adjust for drift
    cam_beta = [ones(size(framet)) framet] \ pulse_times_faceCam;
    framet_sync_axona = [ones(size(framet)) framet] * cam_beta;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% synchronize face cam to unity
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% truncate to correct number of pulses
num_pulses = min(numel(pulse_times_unity), numel(pulse_times_vr));
pulse_times_unity = pulse_times_unity(1:num_pulses);
pulse_times_vr = pulse_times_vr(1:num_pulses); 

% linearly regress vr time on axona time
if corr(diff(pulse_times_vr), diff(pulse_times_unity)) < 0.999
    error('\nERROR: Something wrong with VR syncing (pulses not aligning)\n');
else        
    beta = [ones(size(pulse_times_unity)) pulse_times_unity] \ pulse_times_vr;
end

% sync face cam and unity
v.framet_sync = [ones(size(framet_sync_axona)) framet_sync_axona] * beta;
    
end
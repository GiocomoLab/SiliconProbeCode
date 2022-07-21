%function sync_vr_to_np(data_dir)
addpath(genpath('C:\code\spikes'));
addpath(genpath('C:\code\npy-matlab'));

% location of data
data_dir = 'F:\Alex\AA_190709_1\neuropixels_data\AA_190709_1_0726_gain_g0';
session_name = 'MOV_190726_12-42-33';



[~,main_name]=fileparts(data_dir);
animal_name = strsplit(main_name,'_');
animal_name = animal_name{1};

NIDAQ_file = dir(fullfile(data_dir,'*nidq.bin'));
NIDAQ_file = fullfile(data_dir,NIDAQ_file(1).name);
NIDAQ_config = dir(fullfile(data_dir,'*nidq.meta'));
NIDAQ_config = fullfile(data_dir,NIDAQ_config(1).name);
spike_dir = fullfile(data_dir,strcat(main_name,'_imec0'));

%get the nidaq sample rate & get number of recorded nidaq channels
dat=textscan(fopen(NIDAQ_config),'%s %s','Delimiter','=');
names=dat{1};
vals=dat{2};
loc=contains(names,'niSampRate');
sync_sampling_rate=str2double(vals{loc});

loc2=contains(names,'nSavedChans');
n_channels_nidaq=str2double(vals{loc2});

% get neuropixels sync pulse times
fpNIDAQ=fopen(NIDAQ_file);
datNIDAQ=fread(fpNIDAQ,[n_channels_nidaq,Inf],'*int16');
fclose(fpNIDAQ);
syncDat=datNIDAQ(2,:)>1000;


frame_times_np = find(abs(diff(syncDat))==1)+1;
frame_times_np = frame_times_np/sync_sampling_rate;

% read vr position data

delimiter = '\t';
headerLinesIn = 1;

data_array = importdata(fullfile(data_dir,strcat(session_name,'.log')),delimiter,headerLinesIn);

vr_position_data = data_array.data;
%vr_position_data = vr_position_data(1:49334,:);
nu_entries = nnz(~isnan(vr_position_data(1,:)));
%vr_position_data=vr_position_data(49335:end,:);
frame_times_vr=vr_position_data(:,1);



%%
tmp_diff=diff(frame_times_np);
[mm,step_idx]=find(tmp_diff>2);
sess_length=diff([0 step_idx length(frame_times_np)]);
midpoint = ([0 step_idx] + [step_idx length(frame_times_np)])/2;
%step_idx=step_idx+1;
[~,ml]=min(abs(sess_length-numel(frame_times_vr)));
if length(mm)>=1
    figure;
    subplot(2,1,1)
    plot(frame_times_np)
    subplot(2,1,2)
    plot(tmp_diff)
    title(sprintf('found %d blocks',numel(step_idx+2)))
    hold on
    plot(step_idx,tmp_diff(step_idx),'ro')
    
    for im=1:numel(midpoint)
    text(midpoint(im),max(tmp_diff),sprintf('%d',sess_length(im)))
    end
    
    sess=input(sprintf('Which session do you want to extract (suggesting %d)',ml));
    if nu_entries == 3
        extra = 'unlikely';
    else
        extra = 'likely';
    end
    is_mismatch = input(['Is this a MM or PB session (' extra ') [0/1]?']);
    step_idx = [0 step_idx length(frame_times_np)];
    %frame_times_np=frame_times_np(ii+2:end);
    idx_start=step_idx(sess)+1;
    idx_stop = step_idx(sess+1);
    frame_times_np=frame_times_np(idx_start:idx_stop);
else
    is_mismatch=0;
end
%%
if abs(numel(frame_times_np) - numel(frame_times_vr)) <= 1
    idx=1:min(numel(frame_times_np),numel(frame_times_vr)); %use shorter index
    post = frame_times_np(idx)';
    vr_position_data=vr_position_data(idx,:);
    speed = vr_position_data(:,2);
    stim_id = vr_position_data(:,3);

else
    disp('ERROR: number of sync pulses does not match number of frames.')
end
figure
scatter(diff(post),diff(frame_times_vr(idx)),2,1:length(idx)-1)
r=corrcoef(diff(post),diff(frame_times_vr(idx)));
title(sprintf('corr coeff = %0.3f',r(1,2)));
%%
% load spike times
sp = loadKSdir(spike_dir);
%% dirty hack for when kilosort2 used wrong sampling rate
% st=sp.st;
% in_samples=st*32000;
% sp.st=in_samples/30000;
%%
% shift everything to start at zero
offset = post(1);
post = post - offset;

sp.st = sp.st - offset;
sp.vr_session_offset = offset;

% resample position to have constant time bins
speed = interp1(post,speed,(0:0.02:max(post))');
stim_id = interp1(post,stim_id,(0:0.02:max(post))');
vr_data_downsampled=interp1(post,vr_position_data,(0:0.02:max(post)));
post = (0:0.02:max(post))';


% cut off all spikes before and after vr session
keep = sp.st >= 0 & sp.st <= post(end);
sp.st = sp.st(keep);
sp.spikeTemplates = sp.spikeTemplates(keep);
sp.clu = sp.clu(keep);
sp.tempScalingAmps = sp.tempScalingAmps(keep);


save(fullfile(data_dir,strcat(animal_name,'_',session_name,'.mat')),'sp','post','stim_id');

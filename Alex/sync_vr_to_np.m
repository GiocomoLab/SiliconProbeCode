function sync_vr_to_np(data_dir,NIDAQ_file,NIDAQ_config,vr_files,animal_name,tmp_save_loc)
addpath(genpath('C:\code\spikes'));
addpath(genpath('C:\code\npy-matlab'));

parent_dir = fileparts(data_dir);
sync_file_imec = dir(fullfile(parent_dir,'*SY_384_6_500*'));
sync_data_imec = importdata(fullfile(sync_file_imec.folder,sync_file_imec.name));

sync_file_nidaq = dir(fullfile(fileparts(parent_dir),'*XA_0_500*'));
sync_data_nidaq = importdata(fullfile(sync_file_nidaq.folder,sync_file_nidaq.name));
% specify track length

[~,main_name]=fileparts(data_dir);
spike_dir = data_dir;

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
syncDat=datNIDAQ(2,:)>10000;


frame_times_np = find(abs(diff(syncDat))==1)+1;
frame_times_np = frame_times_np/sync_sampling_rate;


%%
% load spike times
sp = loadKSdir(spike_dir);
%% dirty hack for when kilosort2 used wrong sampling rate
% st=sp.st;
% in_samples=st*32000;
% sp.st=in_samples/30000;
%%

%syncDatNIDAQ=datNIDAQ(1,:)>1000;

%ts_NIDAQ = strfind(syncDatNIDAQ,[0 1])/sync_sampling_rate;

% use this for data that has not been processed with CatGT
%correction_slope = alignIMEC_sync(LFP_path,1,ts_NIDAQ);
nE = min(numel(sync_data_imec),numel(sync_data_nidaq));
fit = polyfit(sync_data_imec(1:nE),sync_data_imec(1:nE)-sync_data_nidaq(1:nE),1);
correction_slope = fit(1);
%
% save the old, uncorrected data as sp.st_uncorrected and save the new,
% corrected data as sp.st (as many of your analyses are using sp.st).

sp.st_uncorrected = sp.st; % save uncorrected spike times (st)
st_corrected = sp.st - sp.st * correction_slope; % in two steps to avoid confusion
sp.st = st_corrected; % overwrite the old sp.st
%% do this part for each vr file
for iF=1:numel(vr_files)
    try
    parts = strsplit(vr_files(iF).name,'_');
    session_name = [parts{1} '_' parts{1} '_' parts{3}];
    session_name = strrep(vr_files(iF).name,'_position.txt','');
    [vr_data,main_fields] = read_vr_data(vr_files(iF).folder,session_name);
    
    
    [post,fig]=sync_vrFile_NIDAQ(frame_times_np,vr_data.Time);
    
    saveas(fig,fullfile(fileparts(parent_dir),[session_name '.png']))
    close(fig);
    
    %%
    tracklength = floor(max(vr_data.Position)/10)*10;
    
    % shift everything to start at zero
    offset = post(1);
    post = post - offset;
    sp.st = sp.st - offset;
    sp.st_uncorrected = sp.st_uncorrected-offset;
    sp.vr_session_offset = offset;
    
    % resample position to have constant time bins
    for fn = 1:numel(main_fields)
        vr_data_resampled.(main_fields{fn}) = interp1(post,vr_data.(main_fields{fn})',0:0.02:max(post));
    end
    post = (0:0.02:max(post))';
    posx = vr_data_resampled.Position';
    posx([false;diff(posx)<-2])=round(posx([false;diff(posx)<-2])/tracklength)*tracklength; % handle teleports
    
    % compute trial number for each time bin
    trial = [1; cumsum(diff(posx)<-100)+1];
    
    % throw out bins after the last trial
    
    num_trials = max(trial);
    
    keep = trial<=num_trials;
    trial = trial(keep);
    posx = posx(keep);
    post = post(keep);
    for fn=1:numel(main_fields)
        vr_data_resampled.(main_fields{fn}) = vr_data_resampled.(main_fields{fn})(keep);
    end
    
    
    % cut off all spikes before and after vr session
    keep = sp.st >= 0 & sp.st <= post(end);
    sp.st = sp.st(keep);
    sp.spikeTemplates = sp.spikeTemplates(keep);
    sp.clu = sp.clu(keep);
    sp.tempScalingAmps = sp.tempScalingAmps(keep);
    sp.st_uncorrected = sp.st_uncorrected(keep);
    %%
    % save processed data
    
    save(fullfile(fileparts(parent_dir),strcat(animal_name,'_',session_name,'.mat')),'sp','post','posx','vr_data_resampled');
    save(fullfile(tmp_save_loc,strcat(animal_name,'_',session_name,'.mat')),'sp','post','posx','vr_data_resampled');
    catch ME
        warning(ME.message)
        error_log = fopen(fullfile(fileparts(parent_dir),'error.txt'),'a');
        fprintf(error_log, '%s\n', session_name);
fclose(error_log);

    end
end
rmpath(genpath('C:\code\spikes'));
rmpath(genpath('C:\code\npy-matlab'));
end
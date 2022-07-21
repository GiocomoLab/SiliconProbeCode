function sync_vr_to_np(data_dir,NIDAQ_file,NIDAQ_config,vr_files,animal_name,tmp_save_loc,histo_path)
addpath(genpath('C:\code\spikes'));
addpath(genpath('C:\code\npy-matlab'));

parent_dir = fileparts(data_dir);

sync_file_nidaq = dir(fullfile(fileparts(parent_dir),'*XA_0_500*'));
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
sp = loadKSdir_Alex(spike_dir);

%% display batch2batchclustering
try
rez = load(fullfile(spike_dir,'rez.mat'));
rez = rez.rez;
fig = figure();
subplot(1,2,1)

imagesc(rez.ccb,[-5 5])
title('batch 2 batch distance')
axis image
subplot(1,2,2)
imagesc(rez.ccbsort,[-5 5])
title('after sorting')
axis image
saveas(fig,fullfile(spike_dir,'batch2batch.png'))
close(fig)
catch
end

%% dirty hack for when kilosort2 used wrong sampling rate
% st=sp.st;
% in_samples=st*32000;
% sp.st=in_samples/30000;
%%

%syncDatNIDAQ=datNIDAQ(1,:)>1000;

%ts_NIDAQ = strfind(syncDatNIDAQ,[0 1])/sync_sampling_rate;

% use this for data that has not been processed with CatGT
%correction_slope = alignIMEC_sync(LFP_path,1,ts_NIDAQ);
sync_file_imec = dir(fullfile(parent_dir,'*SY_384_6_500*'));
if isempty(sync_file_imec)
    sync_file_imec = dir(fullfile(data_dir,'*SY_384_6_500*'));
end

sync_file_nidaq = dir(fullfile(parent_dir,'*XA_0*'));
if isempty(sync_file_nidaq)
    sync_file_nidaq = dir(fullfile(data_dir,'*XA_0*'));
end

if ~isempty(sync_file_imec) && ~isempty(sync_file_nidaq)
    sync_data_imec = importdata(fullfile(sync_file_imec.folder,sync_file_imec.name));
    
    sync_data_nidaq = importdata(fullfile(sync_file_nidaq.folder,sync_file_nidaq.name));
    nE = min(numel(sync_data_imec),numel(sync_data_nidaq));
    fit = polyfit(sync_data_imec(1:nE),sync_data_imec(1:nE)-sync_data_nidaq(1:nE),1);
    correction_slope = fit(1);
else
    %keyboard
    %LFP_path='Z:\giocomo\export\data\Projects\AlexA_NP\AA_200920_4\AA_200920_4_mismatch_3_g0\AA_200920_4_mismatch_3_g0_imec0'
    %lfp_file = dir(fullfile(data_dir,'*.lf.bin'))
    %LFP_path = fullfile(lfp_file(1).folder,lfp_file(1).name);
    LFP_path = data_dir;
    syncDatNIDAQ=datNIDAQ(1,:)>1000;
    ts_NIDAQ = strfind(syncDatNIDAQ,[0 1])/sync_sampling_rate;
    correction_slope = alignIMEC_sync(LFP_path,1,ts_NIDAQ);
end

%
% save the old, uncorrected data as sp.st_uncorrected and save the new,
% corrected data as sp.st (as many of your analyses are using sp.st).

sp.st_uncorrected = sp.st; % save uncorrected spike times (st)
st_corrected = sp.st - sp.st * correction_slope; % in two steps to avoid confusion
sp.st = st_corrected; % overwrite the old sp.st

%% do this part for each vr file
sp_orig = sp;

%%
for iF=1:numel(vr_files)
    sp=sp_orig;
    try
        
        %parts = strsplit(vr_files(iF).name,'_');
        %session_name = [parts{1} '_' parts{1} '_' parts{3}];
        %session_name = strrep(vr_files(iF).name,'_position.txt','');
        %[vr_data,main_fields] = read_vr_data(vr_files(iF).folder,session_name);
        vr_data=readtable(vr_files{iF},'Delimiter','\t','FileType','text');
        
        [post,fig]=sync_vrFile_NIDAQ(frame_times_np,vr_data.time);
        [~,session_name]=fileparts(vr_files{iF});
        xlim([0.01 0.03])
        ylim([0.01 0.03])
        saveas(fig,fullfile(data_dir,strcat(session_name,'.png')))
        close(fig);
        
        %%
        main_fields = vr_data.Properties.VariableNames;

        if ismember('xpos',main_fields) 
        tracklength = floor(max(vr_data.xpos)/10)*10;
        else
            tracklength = nan;
        end
        
        % shift everything to start at zero
        offset = post(1);
        post = post - offset;
        sp.st = sp.st - offset;
        sp.st_uncorrected = sp.st_uncorrected-offset;
        sp.vr_session_offset = offset;
        % resample position to have constant time bins
        for fn = 2:numel(main_fields) % because we dont need time resampled
            vr_data_resampled.(main_fields{fn}) = interp1(post,vr_data.(main_fields{fn}),0:0.02:max(post));
        end
        %nS=numel(post);
        vr_data.time = post'; %save new time (same, but starting at 0)
        post = (0:0.02:max(post))';
        if ismember('xpos',main_fields)
            posx = vr_data_resampled.xpos';
            posx([false;diff(posx)<-2])=round(posx([false;diff(posx)<-2])/tracklength)*tracklength; % handle teleports
        else
            posx = nan;
        end
        % compute trial number for each time bin
        %trial = [1; cumsum(diff(posx)<-100)+1];
        
        % throw out bins after the last trial
        
        %num_trials = max(trial);
        
        %keep = trial<=num_trials;
        %posx = posx(keep);
        %post = post(keep);
%         for fn=2:numel(main_fields)
%             vr_data_resampled.(main_fields{fn}) = vr_data_resampled.(main_fields{fn})(keep);
%         end
        
        
        % cut off all spikes before and after vr session
        keep = sp.st >= 0 & sp.st <= post(end);
        sp.st = sp.st(keep);
        %sp.spikeTemplates = sp.spikeTemplates(keep);
        sp.clu = sp.clu(keep);
        %sp.tempScalingAmps = sp.tempScalingAmps(keep);
        sp.st_uncorrected = sp.st_uncorrected(keep);
        %%
        % save processed data
        if ~isempty(histo_path)
            anatomy = readtable(histo_path);
        else
            anatomy = [];
        end
        save(fullfile(data_dir,strcat(session_name,'.mat')),'sp','post','posx','vr_data_resampled','vr_data','anatomy');
        save(fullfile(tmp_save_loc,strcat(session_name,'.mat')),'sp','post','posx','vr_data_resampled','vr_data','anatomy');
    catch ME
        %keyboard
        %rethrow(ME)
        warning(ME.message)
        warning(sprintf('%s\n', vr_files{iF}));
        error_log = fopen(fullfile(fileparts(parent_dir),'error.txt'),'a');
        fprintf(error_log, '%s\n', vr_files{iF});
        fclose(error_log);
        
    end
end
rmpath(genpath('C:\code\spikes'));
rmpath(genpath('C:\code\npy-matlab'));
end
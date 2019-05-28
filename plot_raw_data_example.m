addpath(genpath('C:/code/neuropixel-utils')) % from: https://github.com/alex-attinger/neuropixel-utils
addpath(genpath('C:/code/AlexA_Library'))
%load the processed data
session_name = 'npJ1_0520_baseline_2';
load('Y:\giocomo\attialex\NP_DATA\npJ1_0520_baseline_2')

ks_dir = 'F:\J1\npJ1_0520_baseline_g0\npJ1_0520_baseline_g0_imec0';
channelMapFile = 'C:\code\KiloSort2\configFiles\neuropixPhase3B1_kilosortChanMap.mat';
ks = Neuropixel.KiloSortDataset(ks_dir,'channelMap',channelMapFile);
ks.load()
metrics = ks.computeMetrics();






%% some driftmaps
figure
metrics.plotDriftmap()  

figure
cluster_ids = metrics.cluster_ids(1:5:metrics.nClusters);
metrics.plotClusterDriftmap('cluster_ids', cluster_ids);

figure
metrics.plotClusterDriftmap('cluster_ids', ks.clusters_good([51]));
%% raw waveforms waveforms

trial_pre=64:75;
good_cells = ks.clusters_good;
h=figure('Position',[680   363   384   615]);






for k=1%:numel(good_cells)
    clusterID = good_cells(k);
    
    post_offset = post+sp.vr_session_offset;
    %trial range pre
    
    start_pre = post_offset(find((trial-trial_pre(1))==0,1));
    stop_pre = post_offset(find((trial-trial_pre(end))==0,1));
    
   
    vr_pre = sp.st>(start_pre-sp.vr_session_offset) & sp.st<(stop_pre-sp.vr_session_offset) & sp.clu == clusterID;
    
    start_pre = start_pre*30000;
    stop_pre = stop_pre*30000;
    idxPre = ks.spike_times > start_pre & ks.spike_times <stop_pre & ks.spike_clusters == clusterID;
    
    
        %extracts waveform from best_n_channels
        snippetSetPre = ks.getWaveformsFromRawData('cluster_ids', clusterID,'num_waveforms', Inf, 'best_n_channels', 20, 'car', true,'spike_idx',idxPre);
        meanwfPre=mean(snippetSetPre.data,3);
        
       

        figure

        title(sprintf('cluid = %i',good_cells(k)))
        tvec=snippetSetPre.window(1):snippetSetPre.window(2);
        tvec=double(tvec)/30;
        subplot(2,1,1)
        plot(tvec,meanwfPre) %
        subplot(2,1,2)
        plot(tvec,meanwfPre(1,:))
           
    
   end
%%

% you could also use at
% metrics.spike_amplitude(metrics.spike_clusters==cluid), or
% metrics.spike_depth((metrics.spike_clusters==cluid))

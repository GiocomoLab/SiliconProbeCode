
function spikeStruct = loadKSdir_Alex(ksDir)


% load spike data

dat=textscan(fopen(fullfile(ksDir, 'params.py')),'%s %s','Delimiter','=');
loc=contains(dat{1},'sample_rate');
sampling_rate=str2double(dat{2}{loc})*1.0;
spikeStruct.sample_rate = sampling_rate;
ss = readNPY(fullfile(ksDir, 'spike_times.npy'));
st = double(ss)/spikeStruct.sample_rate;


clu = readNPY(fullfile(ksDir, 'spike_clusters.npy'));
try
    cgs=readtable(fullfile(ksDir,'cluster_group.tsv'),'FileType','text');
catch ME
    warning('using ks cluster label')
    cgs = readtable(fullfile(ksDir,'cluster_KSLabel.tsv'),'FileType','text');
    cgs.group = cgs.KSLabel;
end
label_files.ks_cluster = fullfile(ksDir,'cluster_KSLabel.tsv');
label_files.rf_cluster = fullfile(ksDir,'classifier_cluster.txt');
%label_files.heuristic_cluster = fullfile(ksDir,'classifier_cluster_heuristic.txt');
label_files.heuristic_cluster = fullfile(ksDir,'heuristic_cluster.txt');
fn = fieldnames(label_files)
for iF=1:numel(fn)
    tmp = label_files.(fn{iF});
    if isfile(tmp)
        spikeStruct.(fn{iF})=readtable(tmp,'FileType','text');
    else
        spikeStruct.(fn{iF})=[];
    end
end


cids = cgs.cluster_id;

LABELS.mua = 1;
LABELS.good = 2;
LABELS.noise = 0;
LABELS.unsorted = 0;

cgs_temp = nan(size(cids));
try
    for iC=1:numel(cgs_temp)
        cgs_temp(iC) = LABELS.(cgs.group{iC});
    end
catch ME
    disp('using ks label')
    for iC=1:numel(cgs_temp)
        cgs_temp(iC) = LABELS.(cgs.KSLabel{iC});
    end
end




coords = readNPY(fullfile(ksDir, 'channel_positions.npy'));
ycoords = coords(:,2); xcoords = coords(:,1);

spikeStruct.st = st;
spikeStruct.clu = clu;
spikeStruct.cgs = cgs_temp;
spikeStruct.cids = cids;
spikeStruct.xcoords = xcoords;
spikeStruct.ycoords = ycoords;

if isfile(fullfile(ksDir,'waveform_metrics.csv'))
    
    waveform_metrics = readtable(fullfile(ksDir,'waveform_metrics.csv'));
    spikeStruct.waveform_metrics = waveform_metrics;
else
    disp('no metric file')
end

end
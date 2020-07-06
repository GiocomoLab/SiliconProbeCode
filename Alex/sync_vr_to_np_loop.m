folders2process = dir('F:\CatGT\cat*');
oak = 'Z:\giocomo\export\data\Projects\AlexA_NP';
tmp_save_loc = 'F:\Alex\matfiles_new';
for iF = 4
    name = folders2process(iF).name;
    elements = strsplit(name,'_');
    animal = [elements{2} '_' elements{3} '_' elements{4}];
    %disp(animal);
    probe_folder_name=[sprintf('%s_',elements{2:end}) 'imec0'];
    exp_folder_name = [sprintf('%s_',elements{2:end})];
    exp_folder_name = exp_folder_name(1:end-1);
    %recording_date =
    probe_folder_path = fullfile(folders2process(iF).folder,folders2process(iF).name,probe_folder_name);
    config_file = dir(fullfile(probe_folder_path,'*.meta'));
    config_file = fullfile(probe_folder_path,config_file(1).name);
    dat=textscan(fopen(config_file),'%s %s','Delimiter','=');
    names=dat{1};
    vals=dat{2};
    loc=contains(names,'fileCreateTime_original');
    recording_date=(vals{loc});
    recording_date = strsplit(recording_date,'T');
    recording_date = recording_date{1};
    %disp(recording_date);
    recording_date = strrep(recording_date(3:end),'-','');
    vr_path = fullfile(oak,animal,'VR',[recording_date '*' 'position.txt']);
    vr_files = dir(vr_path);
    disp(numel(vr_files))
    nidaq_files = dir(fullfile(oak,animal,'neuropixels_data',exp_folder_name,'*nidq*'));
    if isempty(nidaq_files)
        nidaq_files = dir(fullfile(oak,'process',exp_folder_name,'*nidq*'));
    end
    nidaq_data = fullfile(nidaq_files(1).folder,nidaq_files(1).name);
    nidaq_config = fullfile(nidaq_files(1).folder,nidaq_files(2).name);
    spike_dir = fullfile(probe_folder_path,'imec0_ks2');
    sync_vr_to_np(spike_dir,nidaq_data,nidaq_config,vr_files,animal,tmp_save_loc);
 end


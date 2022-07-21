%%
folders = dir('H:\catGT2\cat*');
session_table = readtable('Z:\giocomo\attialex\Histology\session_february.xlsx');
%%
session_infos = dir('Z:\giocomo\export\data\Projects\AlexA_NP\AA_210114_5*\session_info.csv');
sn = {};
histo=[];
for iS=1:numel(session_infos)
    session_info = readtable(fullfile(session_infos(iS).folder,session_infos(iS).name),'Delimiter',',');
    sn = cat(1,sn,session_info.SessionName(:));
    histo = cat(1,histo,session_info.Histology(:));
end

%%
for iF=1:numel(sn)%16:numel(folders)
    %glx_name='AA_210114_5_210217_mismatch_3_g0';
    %glx_name =strrep(folders(iF).name,'catgt_','');
    glx_name = sn{iF};
    parts = strsplit(glx_name,'_');
    exp_day = parts{4};
    %exp_day = '210208';
    % vr_file = {"AA_200920_4_MM_13-14-15.log",...
    %     "AA_200920_4_MMdark_14-01-38.log",...
    %     "AA_200920_4_PB_13-47-38.log"
    %     };
    
    %%
    %root = fullfile('H:\CatGT2',strcat('catgt_',glx_name),strcat(glx_name,'_imec0'));
    %root = 'Z:\giocomo\export\data\Projects\AlexA_NP\AA_200920_4\ks_data\AA_200920_4_mismatch_3_g0';
    parts = strsplit(glx_name,'_');
    animal = strcat(parts{1},'_',parts{2},'_',parts{3});
    
    %data_dir = root;
    oak_root = 'Z:\giocomo\export\data\Projects\AlexA_NP'

    oak_root = fullfile(oak_root,animal);
    ks_dir = fullfile(oak_root,'ks_data',glx_name);

    oak_root_glx = fullfile(oak_root,glx_name);
    
    NIDAQ_file = dir(fullfile(oak_root_glx,'*nidq.bin'));
    NIDAQ_file = fullfile(NIDAQ_file(1).folder,NIDAQ_file(1).name);
    NIDAQ_config = strrep(NIDAQ_file,'.nidq.bin','.nidq.meta')
    %%
    
    vr_file = dir(fullfile(oak_root,['*' exp_day '*.log']));
    vr_file = {vr_file(:).name};
    vr_file_full={};
    for fn = 1:numel(vr_file)
        vr_file_full{fn}=fullfile(oak_root,vr_file{fn});
    end
    
    %%
    if histo(iS)
        histo_loc = fullfile(oak_root,'histology',strcat(glx_name,'_KS25.csv'));
    else
        histo_loc = '';
    end
    
    %%
    sync_vrPanda_to_np(ks_dir,NIDAQ_file,NIDAQ_config,vr_file_full,animal,'F:\Alex\new_2',histo_loc)
end
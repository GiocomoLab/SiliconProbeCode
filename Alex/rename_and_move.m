matfiles = dir('F:\Alex\*\*\*\*.mat');
np_2='F:\NP_DATA_2';
for iF=1:numel(matfiles)
    [~,sn]=fileparts(matfiles(iF).name);
    orig = fullfile(matfiles(iF).folder,matfiles(iF).name);
    folders = split(matfiles(iF).folder,filesep);
    parent = folders{end};
    parts = split(parent,'_');
    dat = parts{2};
    numb = parts{3};
    new_name = sprintf('AA_%s_%s_%s.mat',dat,numb,sn(4:end));
    copyfile(orig,fullfile(matfiles(iF).folder,new_name));
    copyfile(orig,fullfile(np_2,new_name))
end
    
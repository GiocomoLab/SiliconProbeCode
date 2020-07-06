function [vr_data,headers] = read_vr_data(vr_path,session_name)

% read vr position data

    fn_vr = fullfile(vr_path,strcat(session_name,'_position.txt'));
    fn_trial = fullfile(vr_path,strcat(session_name,'_trial_times.txt'));
    fn_lick = fullfile(vr_path,strcat(session_name,'_licks.txt'));
    fn_meta = fullfile(vr_path,strcat(session_name,'_meta.txt'));
    if ~isfile(fn_meta)
        %maybe meta is still in parent dir
        fn_meta = fullfile(fileparts(vr_path),strcat(session_name,'_meta.txt'));
    end
    fp_meta=fopen(fn_meta);
tmp = textscan(fp_meta,'%s');
fclose(fp_meta);
headers = tmp{1};

% formatSpec = '';
% for ih = 1:numel(headers)-1
%     formatSpec = strcat(formatSpec,'%f');
% end
% formatSpec = strcat(formatSpec,'%[^\n\r]');
%  %formatSpec = '%f%f%f%f%f%[^\n\r]';
% delimiter = '\t';

% fid = fopen(fn_vr,'r');
% dataArray = textscan(fid, formatSpec, 'Delimiter', delimiter, 'TextType', 'string', 'EmptyValue', NaN,  'ReturnOnError', false);
% fclose(fid);
% 
dataArray = importdata(fn_vr);
if size(dataArray,2) ~=numel(headers)
    keyboard
end
nu_entries = nnz(all(~isnan(dataArray),2));

for iF=1:numel(headers)
    vr_data.(headers{iF}) = dataArray(1:(nu_entries-1),iF);
end


% read vr trial data
if isfile(fn_trial)
vr_trial_data = importdata(fn_trial);
% fclose(fid);
% trial_contrast = [100; vr_trial_data(:,2)];
% trial_gain = [1; vr_trial_data(:,3)];
% num_trials = numel(trial_gain);
vr_data.vr_trial_data = vr_trial_data;
end

% read vr licking data

if isfile(fn_lick)
vr_lick_data = importdata(fn_lick);
vr_data.vr_lick_data= vr_lick_data;

end


% set vr frame times to be the time of neuropixels pulses
% make sure the number of frames matches (can be off by one because of
% odd/even numbers of frames)
%%
end
function process_data
% to batch process raw data from NP and H3 recordings
% IL created 4/16/2019
%
% Input:
% struct, d, with the fields bin and files
% d.h3 : bool
%   set true for H3 data
% d.folders : string
%   data folder for each recording session
% d.files : string
%   file name for each recording session (without trailing .bin)

root = 'C:/data/ToProcess/'; % path to the data folders
d = load([root 'data.mat']);

for f = 1:numel(d.h3)
    if d.h3(f) % H3 data
        % convert to bin file
        d.files{f} = neuralynx2kilosort(fullfile(root, d.folders{f}));
        d.files{f} = erase(d.files{f}, '.bin');
        
        % run kilsort1 with H3 params
        master_file_H3(d.folders{f}, d.files{f})
    else % neuropixels data
        % run kilsort2 with NP params
        master_kilosort(d.folders{f}, d.files{f})
    end
end
end
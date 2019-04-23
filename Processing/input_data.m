function input_data
root = 'C:/data/ToProcess';
if isfile([root 'data.mat'])
    load([root 'data.mat'])
else
    data = struct;
end

% add data to struct for processing
N = input('number of files to add: ');

for n = 1:N
    fprintf(['\nenter data for file ', n, ' of ', N])
    h3 = input('\nthis is an H3 recording (true/false): ');
    file =...
        input('\nfile name, without file extension: ', 's');
    folder =...
        input('\npath to folder containing recording file, without trailing backslash: ', 's');
    if isfile([root 'data.mat'])
        data.h3 = [data.h3 h3];
        data.files = {data.files, file};
        data.folders = {data.folders, folder};
    else
        data.h3 = h3;
        data.files = file;
        data.folders = folder;
    end
end

save([root 'data'],'data');
% directoryPath = 'F:\H1_flipped\2019-03-12_10-21-28'
function neuralynx2kilosortSherlock(directories, target_dir)
    % convert H3 probe data to bin format for kilosort analysis
    % created by Kei Masuda
    % IL edited 4/9/19
    %
    % Inputs:
    % -------
    % directories : cell array
    %   contains path(s) to data folders, no trailing backslash
    % target_dir : string
    %   path to folder to save output; optional, default is directorypath
    %
    % Outputs:
    % --------
    % .bin file that is a data matrix with samples of size 64channels x numOfSamples
    % if multiple files from the same date, they will be concatenated in
    %   order of recording
    
    % check input arguments
    if iscell(directories)
        directories = string(directories);
    end
    if nargin == 1
        target_dir = directories{1};
    end
    
    fprintf(strcat('\nStart Processing: ', datestr(now,'mmmm dd, yyyy HH:MM:SS AM'),'\n'));
    numOfChannels = 64;
    num_files = size(directories, 2);
    sample_idx = [1 zeros(1, num_files)];
    
    for dir = 1:num_files
        directoryPath = directories{dir};
        fprintf(strcat('\nProcessing session ', num2str(dir), ' out of ', num2str(num_files), '\n'))
        for csc = 1:numOfChannels
            cscPath = fullfile(directoryPath, ['CSC_HP_' num2str(csc) '.ncs']);
            %cscPath = fullfile(directoryPath, ['CSC' num2str(csc) '.ncs']);

            % load neuralynx file, linearize samples, convert to int16
            [Samples,header]=Nlx2MatCSC(cscPath, [0 0 0 0 1], 1, 1, [] );
            tmp=split(header{17}); %assuming conversion factor is in here;
            conv_factor = str2double(tmp{2}); % in volts
            conv_factor = conv_factor*10e6; % in micro volts
            %conv_factor = 1;
            Samples = reshape(Samples,1,[])*-1*conv_factor; 
            Samples= int16(Samples); 

            % pre-allocate dataMatrix size on first pass of each session
            if dir == 1 && csc == 1 
               sample_idx(dir + 1) = size(Samples,2);
               dataMatrix = zeros(numOfChannels,sample_idx(dir + 1),'int16');
            elseif csc == 1
               sample_idx(dir + 1) = size(Samples,2);
               dataMatrix = [dataMatrix zeros(numOfChannels,sample_idx(dir + 1),'int16')];
            end
            
            % allocate csc data to appropriate rows/columns of data matrix
            dataMatrix(csc, sample_idx(dir):sample_idx(dir + 1)) = Samples; 
            fprintf(strcat('\nProcessed: ', num2str(csc), ' out of 64 CSC files.'));
        end
    end
    
    [~,Name,~] = fileparts(directoryPath);
    fid = fopen(fullfile(target_dir,[Name '_dataMatrix.bin']), 'w'); 
    fwrite(fid, dataMatrix, 'int16');
    fclose(fid);
    fprintf(strcat('\nDone Processing: ', datestr(now,'mmmm dd, yyyy HH:MM:SS AM'),'\n'));
end
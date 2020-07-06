function correction_slope = alignIMEC_sync(IMEC_path,isLFP,NIDAQ_pulses)
% Now, we do the same, but from the perspective of the Imec board. 
LFP_config = dir(fullfile(IMEC_path,'*.lf.meta'));
LFP_config = fullfile(LFP_config.folder,LFP_config.name);

LFP_file = dir(fullfile(IMEC_path,'*.lf.bin'));
LFP_file = fullfile(LFP_file.folder,LFP_file.name);

dat=textscan(fopen(LFP_config),'%s %s','Delimiter','=');
names=dat{1};
vals=dat{2};
loc=contains(names,'imSampRate');
lfp_sampling_rate=str2double(vals{loc});

% for loading only a portion of the LFP data
fpLFP = fopen(LFP_file);
fseek(fpLFP, 0, 'eof'); % go to center of file
fpLFP_size = ftell(fpLFP); % report size of file
fpLFP_size = fpLFP_size/(2*384); 
fclose(fpLFP);

% get the sync pulse times relative to the Imec board
fpLFP=fopen(LFP_file);
fseek(fpLFP,384*2,0);
ftell(fpLFP);
datLFP=fread(fpLFP,[1,round(fpLFP_size/4)],'*int16',384*2); % this step takes forever
fclose(fpLFP);
syncDatLFP=datLFP(1,:)>10; 
ts_LFP = strfind(syncDatLFP,[0 1])/lfp_sampling_rate;
% ts_LFP: these are the sync pulse times relative to the Imec board

% PART 2: TIME CORRECTION
lfpNIDAQdif = ts_LFP - NIDAQ_pulses(1:numel(ts_LFP)); % calculate the difference between the sync pulse times
fit = polyfit(ts_LFP, lfpNIDAQdif, 1); % linear fit 
correction_slope = fit(1); % this is the amount of drift we get per pulse (that is, per second)

end
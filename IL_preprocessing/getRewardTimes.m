function [rewardtimes, rewardcenters, rewardautomatic] = getRewardTimes(session, dir)
% Gets reward info and whether they were automatically delivered
% IL Apr 2019

reward_file = fullfile(dir, 'VR', strcat(session, '_reward.txt'));
fid = fopen(reward_file);
data = textscan(fid,'%f %d',Inf, 'Delimiter', '\t');
loc_data = data{1};
trials = data{2};
fclose(fid);

idx = [1:3:numel(loc_data)];
rewardtimes = loc_data(idx);
% rewardtrials = trials(idx);
rewardcenters = loc_data(idx + 1);
rewardautomatic = trials(idx + 1);
% miss = loc_data(idx + 2); ??


end
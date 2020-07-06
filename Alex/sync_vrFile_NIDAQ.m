function [post,fig] = sync_vrFile_NIDAQ(vr_frame_times_nidaq,vr_frame_times_file)
tmp_diff=diff(vr_frame_times_nidaq);
%[mm,step_idx]=find(tmp_diff>2); %%CHANGE BACK TO 2
t=max(diff(vr_frame_times_file))+min(diff(vr_frame_times_file));
[mm,step_idx]=find(tmp_diff>t);

sess_length=diff([0 step_idx length(vr_frame_times_nidaq)]);
midpoint = ([0 step_idx] + [step_idx length(vr_frame_times_nidaq)])/2;
%step_idx=step_idx+1;
[~,ml]=min(abs(sess_length-numel(vr_frame_times_file)));
%     figure;
%     subplot(2,1,1)
%     plot(vr_frame_times_nidaq)
%     subplot(2,1,2)
%     plot(tmp_diff)
%     title(sprintf('found %d blocks',numel(step_idx+2)))
%     hold on
%     plot(step_idx,tmp_diff(step_idx),'ro')
%     
%     for im=1:numel(midpoint)
%     text(midpoint(im),max(tmp_diff),sprintf('%d',sess_length(im)))
%     end
%     
%     sess=input(sprintf('Which session do you want to extract (suggesting %d)',ml));
   
    sess=ml;
    step_idx = [0 step_idx length(vr_frame_times_nidaq)];
    idx_start=step_idx(sess)+1;
    idx_stop = step_idx(sess+1);
    vr_frame_times_nidaq=vr_frame_times_nidaq(idx_start:idx_stop);

%%
    idx=1:min(numel(vr_frame_times_nidaq),numel(vr_frame_times_file)); %use shorter index
    post = vr_frame_times_nidaq(idx);
if abs(numel(vr_frame_times_nidaq) - numel(vr_frame_times_file)) > 1

   

    warning('number of sync pulses does not match number of frames.')
end
fig = figure;
scatter(diff(post),diff(vr_frame_times_file(idx)),2,1:length(idx)-1)
r=corrcoef(diff(post),diff(vr_frame_times_file(idx)));
title(sprintf('corr coeff = %0.3f',r(1,2)));
xlabel(sprintf('n DAQ %d, n File: %d',numel(vr_frame_times_nidaq),numel(vr_frame_times_file)))
end
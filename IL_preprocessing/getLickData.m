function [lickx, lickt] = getLickData(session, dir)

fid = fopen(fullfile(dir, strcat('\VR\', session, '_licks.txt')),'r');
vr_lick_data = fscanf(fid, '%f', [2,inf])';
fclose(fid);
lickx = vr_lick_data(:,1);
lickt = vr_lick_data(:,2);

end
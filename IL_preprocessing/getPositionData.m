function [posx, post] = getPositionData(session, root)
% opens position text file from that session and returns
% unprocessed posx and post vectors
% Malcolm Campbell 5/21/2015
% updated file structure 5/9/2019

pos_file = [root '\VR\' session '_position.txt'];
fid = fopen(pos_file);
pos = fscanf(fid,'%f',[2 Inf])';
posx = pos(:,1);
post = pos(:,2);
fclose(fid);

end
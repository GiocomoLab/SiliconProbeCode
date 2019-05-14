function crop_vid(p, num_roi)
% make a cropped version(s) of a video by drawing ROI(s)

% Input:
%   p       =   universal params spreadsheet
%   num_roi =   number of cropped videos to create (optional, default is 1)

if ~exist('num_roi','var')
    num_roi = 1;
end

% make directory to save video files
baseFolder = p.WorkingDirectory{1};
vid_dir = [baseFolder 'Analysis\' mouse '\VR\dlc_video\' session '\'];
if ~exist (vid_dir, 'file')
    mkdir(vid_dir);
end

% align video to VR session 
disp('Getting video params...')
[videoParams] = syncAxonaToFaceCam(mouse, session, p);
vid = VideoReader([baseFolder mouse '\Video\' session '.mp4']);

num_frames = videoParams.num_frames;
framet = videoParams.framet_sync;
frame_idx = find(framet >= 0 & framet <= max(post));

% create cropped video for each ROI
for r = 1:num_roi
    for i = 1:max(frame_idx)
        frame = readFrame(vid);
        
        % using the first VR frame, set the ROI
        if i == frame_idx(1)
            frame = rgb2gray(frame);

            % make fig
            h = figure();
            ax = axes('Parent', h);
            imshow(frame, 'Parent', ax);
            title(ax, sprintf('Frame #%d', 1));
            set(gcf,'Units','normalized')
            ax.Position = [0,0,1,1];

            % draw ROI for cropped video
            disp('Ready to draw ROI? (press any key to continue)')
            pause
            [roi, roi_p] = makeROI(frame, h);
            disp('Ready to identify pupil? (press any key to continue)')
            pause
            [pupil_val,~] = makeROI(frame, h);
            thresh = mean(mean(pupil_val));
            pupil_roi(pupil_roi > thresh) = 1; % threshold
            pupil_roi(pupil_roi < thresh) = 0;
            figure()
            imshow(pupil_roi)
        end
    end
end

end
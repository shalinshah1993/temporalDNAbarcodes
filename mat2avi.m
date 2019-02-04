function mat2avi(file, folderPrefix, incFactor)
    % file is the mat file name
    %
    % folderPrefix is one of these: drft_crct, mat, filt
    %
    % incFactor is between 1 and number of frames. It is the increment
    % factor between two frames
    
    % Open mat file from the right folder
    fileName = strsplit(file, '.');
    matFile = matfile(strcat('tmp/', folderPrefix, '/', fileName{1}, '.mat'));
    [~, ~, nFrames] = size(matFile,'data');
    
    % Create a video writer object
    fprintf('Writing video frames...\n');
    video = VideoWriter(strcat('video/', fileName{1}, '.avi'), 'Grayscale AVI');
    open(video);
    for iFrame = 1:incFactor:nFrames
        % convert uint16 pixels to uint8 since AVI only supports 8-bit
        writeVideo(video, im2uint8(matFile.data(:,:,iFrame)));
    end
    
    fprintf('Finished writing video.\n');
    close(video);
end
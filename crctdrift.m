function crctdrift(file, toDebug)
    % This function expect that the video file entered already has drift
    % estimated using estdrift and existing mat file in
    % drft_trc\<FILENAME>. The output file will be saved a mat file in the
    % drft_crct\<FILENAME> folder.
    % 
    % file is a .AVI file name
    %
    % toDebug is 0 or 1
    %
    % Created by SHALIN SHAH (shalin.shah@duke.edu)
    % Date created 08/09/2018
    frameSize = 512;
    
    % Load life mat file
    fileName = strsplit(file, '.');
    lifMatFile = matfile(strcat('tmp/mat/', fileName{1}, '.mat'));
    
    fprintf('Loading drift trace file...\n');
    if ~exist(strcat('tmp/drft_trc/', fileName{1}, '.mat'), 'file')
        fprintf('Drift trace file does not exists. \n');
        return
    end
    
    % Load drift trace file
    driftData = load(strcat('tmp/drft_trc/', fileName{1}, '.mat'));
    estDrift = driftData.drift;
    figure(); plot(estDrift); legend('X-direction', 'Y-direction')
    
    % Create a new 3D array and correct drift frame-by-frame
    fprintf('Loaded drift trace, correcting drift...\n');
    dcMatFile = matfile(strcat('tmp/drft_crct/', fileName{1}, '.mat'));
    dcMatFile.Properties.Writable = true;
    [~, ~, nFrames] = size(lifMatFile,'data');
    for iFrame = 1:2:nFrames
         A = imtranslate(lifMatFile.data(:,:,iFrame), ...
                                [-estDrift(iFrame, 1) -estDrift(iFrame, 2)]);
         B = imtranslate(lifMatFile.data(:,:,iFrame+1), ...
                            [-estDrift(iFrame+1, 1) -estDrift(iFrame+1, 2)]);
        dcMatFile.data(1:frameSize,1:frameSize,iFrame:iFrame+1) = cat(3, A, B);
    end
    
    fprintf('Finished correcting for drift.\n')
    if toDebug
        % write every 500th frame and save it 
        mattovid(file, 'drft_crct', 500);
    end
    
end
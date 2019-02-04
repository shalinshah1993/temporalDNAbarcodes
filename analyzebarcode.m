function analyzebarcode(file, expTime)
    % This function will calculate stats and plot them
    %
    % file should contain full name of video with its extension (eg. AVI)
    %
    % expsrTime is the capture rate in seconds (eg. 0.1)
    
    fileName = strsplit(file, '.');
    % Check if temporal barcode data in .mat format exists
    if ~exist(strcat('tmp/st_chn/', fileName{1}, '.mat'), 'file')
        fprintf('cannot find denoised signal data\n');
        return
    end
    fileData = load(strcat('tmp/st_chn/', fileName{1}, '.mat'));
    stateChain = fileData.stateChain;
    number = num2cell(1:1:length(stateChain));
    temporalBarcode = fileData.temporalBarcode;
    
    data = cellfun(@(x) genOnOffStats2(x, expTime), stateChain, 'UniformOutput',false);
    cellfun(@(w, x, y, z) plotondata2(w, x, y, z), data, number, ...
                                                temporalBarcode, stateChain);

    % save stats from the analyzed state chain data
    if exist(strcat('tmp/stats/', fileName{1}, '.mat'), 'file')
        fprintf('Deleting old stats file and generating new one ...\n');
        delete(strcat('tmp/stats/', fileName{1}, '.mat'));
    end
    save(strcat('tmp/stats/', fileName{1}), 'data', '-v7.3');
end

function plotoffdata(data, spot, raw, fit)
    % plot stats for individual signals 
    meanOnTime = mean(data{1});
    meanOffTime = mean(data{2});
    peaks = log(data{3});
    
    figure(1); hold on;
    plot(1, peaks, '.', 'Color', 'g', 'MarkerSize', 25, 'LineWidth', 4.0)
    xlabel('sample #'); ylabel('# peaks'); box on; xlim([0 3])

    fprintf('\ndark time %f\n', meanOffTime)
    fprintf('on time %f\n', meanOnTime)
    fprintf('peaks %f\n', peaks)
end

function plotondata1(data, spot, raw, fit)
    % plot on-time1 stats for individual signals. This method should be used
    % to extract only on-time for 2-level signals such as devices 8nt, 9 nt
    % and 10 nt.
    %
    % data is the state chain cell list
    %
    % spot is the sample # of the cell list
    %
    % raw is the raw temporal signal collected 

    meanOnTime = median(data{1});
   
    figure(1); hold on;
    plot(spot, meanOnTime, '.', 'Color', 'b', 'MarkerSize', 35, ...
        'LineWidth', 4.0)
    set(gca, 'YScale', 'log'); 
    xlabel('sample #');
    ylabel('mean on-time (s)');
    box on;
    
%     figure(2);
%     subplot(2, 1, 1); plot(raw); 
%     subplot(2, 1, 2); plot(fit); 
end

function plotondata2(data, spot, raw, fit)
    % plot on-time2 stats for individual signals. This method should be used
    % to extract on-time and double-blink for 3-level signals such as devices 
    % 10-10, 10-09, 10-08 etc.
    %
    % data is the state chain cell list
    %
    % spot is the sample # of the cell list
    %
    % raw is the raw temporal signal collected 

    meanOnTime = median(data{1});
    meanDbBlinkTimes = mean(data{2});
    noPeak = (data{4});
    
    figure(1); hold on;
    plot(meanOnTime, meanDbBlinkTimes, '.', 'Color', 'b', 'MarkerSize', 35, ...
        'LineWidth', 4.0)
    set(gca, 'YScale', 'log'); 
    xlabel('peaks');
    ylabel('mean on-time (s)');
    box on; 
    
%     figure(2);
%     subplot(2, 1, 1); plot(raw); 
%     subplot(2, 1, 2); plot(fit); 
%     meanOnTime
%     meanDbBlinkTimes
end

function output = genOnOffStats1(barcode, expsrTime)
    % analyse the state chain to calculate # of on-peaks, on-time per
    % peak and off-time per peak
    %
    % barcode is the state chain between 0 and 1 (eg. 0 0 0 0 1 1 1 1 0 0 0)
    % where each point is separated by expsrTime 
    %
    % expsrTime is the capture rate in seconds (eg. 0.1)
    
    offTimes = [];
    onTimes = [];
    onPeaks = 0;
        
    prevChange = 1;
    for iTime = 2 : length(barcode)
        curPeakWidth = iTime - prevChange;
        if barcode(iTime) == 1 && barcode(iTime-1) > 1
            onTimes = [onTimes; expsrTime * curPeakWidth];
            prevChange = iTime;
            onPeaks = onPeaks + 1;
        elseif barcode(iTime) > 1 && barcode(iTime-1) == 1
            offTimes = [offTimes; expsrTime * curPeakWidth];
            prevChange = iTime;
        end
    end
    
    output = cell(3, 1);
    output{1} = onTimes;
    output{2} = offTimes;
    output{3} = onPeaks;
    
%     figure(1); 
%     plot(barcode);
%     fprintf(['\nmean on-time (s): ', num2str(mean(onTimes)), ' mean off-times (s): '...
%             num2str(mean(offTimes)), ' # of peaks: ', num2str(onPeaks)]);
end

function output = genOnOffStats2(barcode, expsrTime)
    % analyse the state chain to calculate # of on-peaks, on-time per
    % peak and off-time per peak. The signals will be analyzed for upto 3
    % states
    %
    % barcode is the state chain between 0 and 1 (eg. 0 0 0 0 1 2 2 1 0 1 0)
    % where each point is separated by expsrTime 
    %
    % expsrTime is the capture rate in seconds (eg. 0.1)
    barcode = barcode - 1;
    
    
    offTimes = [];
    onTimes = [];
    dbBlinkTimes = [];
    onPeaks = 0;
    
    onStart = 1;
    dbOnStart = 1;
    offStart = 1;
    for iTime = 2 : length(barcode)
        if barcode(iTime) == 1 && barcode(iTime-1) == 0
            offTimes = [offTimes; expsrTime * (iTime-offStart)];
            onStart = iTime;
            onPeaks = onPeaks + 1;
        elseif barcode(iTime) == 2 && barcode(iTime-1) == 0
            offTimes = [offTimes; expsrTime * (iTime-offStart)];
            onStart = iTime;
            dbOnStart = iTime;
            onPeaks = onPeaks + 1;
        elseif barcode(iTime) == 0 && barcode(iTime-1) == 1
            onTimes = [onTimes; expsrTime * (iTime-onStart)];
            offStart = iTime;
        elseif barcode(iTime) == 0 && barcode(iTime-1) == 2
            onTimes = [onTimes; expsrTime * (iTime-onStart)];
            dbBlinkTimes = [dbBlinkTimes; expsrTime * (iTime-dbOnStart)];
            offStart = iTime;
        elseif barcode(iTime) == 2 && barcode(iTime-1) == 1
            dbOnStart = iTime;
        elseif barcode(iTime) == 1 && barcode(iTime-1) == 2
            dbBlinkTimes = [dbBlinkTimes; expsrTime * (iTime-dbOnStart)];
        end
    end
    
    output = cell(4, 1);
    output{1} = onTimes;
    output{2} = dbBlinkTimes;
    output{3} = offTimes;
    output{4} = onPeaks;
    
%     figure(1); 
%     plot(barcode);
%     fprintf(['\nmean on-time (s): ', num2str(mean(onTimes)), ' peaks #: '...
%            num2str(mean(onPeaks)), ' mean db-blink times(s): ', num2str(mean(dbBlinkTimes))]);
end

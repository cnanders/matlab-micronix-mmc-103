function [data] = STAGE_MMC_RESPONSE(stages, command)
% to send commands (no response) to serial port -> MMC100
%data = ' ';
%fprintf(['RECEIVE: ' command stages.NL]);
if (stages.enabled > 0)
    fprintf(stages.mmc_portnumber, [command]); % stages.NL]);
    %flushinput(stages.mmc_portnumber);
    data = fscanf(stages.mmc_portnumber,'%s\n');
    if (length(data) > 0)
        if (data(1) == '#')
            data = data;
        else
            data = ' ';
        end
    else
        data = ' ';
    end
else
    data = ' ';
end


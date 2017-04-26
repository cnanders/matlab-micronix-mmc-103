function [data] = STAGE_MMC(stages, command)
% to send commands (no response) to serial port -> MMC100
data = ' ';
%NL = sprintf('\n');
%fprintf(['SEND: ' command stages.NL]);
if (stages.enabled > 0)
    fprintf(stages.mmc_portnumber, [command]); % stages.NL]);
else
    %
end

%flushinput(stages.mmc_portnumber);

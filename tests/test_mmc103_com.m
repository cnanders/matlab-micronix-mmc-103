[cDirThis, cName, cExt] = fileparts(mfilename('fullpath'));

% Add src
addpath(genpath(fullfile(cDirThis, '..', 'src')));

% 'u16TcpipPort', 4001 ...
% 'cTerminator', 'LF', ...

mmc103 = micronix.MMC103(...
    'cConnection', micronix.MMC103.cCONNECTION_SERIAL, ...
    'cTerminator', 'LF/CR', ...
    'cPort', 'COM3' ...
);

%{
mmc103 = micronix.MMC103(...
    'cPort', 'COM2' ...
);
%}
mmc103.init();
mmc103.connect();
mmc103.comm.Terminator


% mmc103.disconnect();






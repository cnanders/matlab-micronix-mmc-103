[cDirThis, cName, cExt] = fileparts(mfilename('fullpath'));

% Add src
addpath(genpath(fullfile(cDirThis, '..', 'src')));

mmc103 = micronix.MMC103(...
    'cTcpipHost', '192.168.0.4', ...
    'u16TcpipPort', 966 ...
);
mmc103.init();
mmc103.connect();
mmc103.c.Terminator


% mmc103.disconnect();






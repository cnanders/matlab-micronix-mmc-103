[cDirThis, cName, cExt] = fileparts(mfilename('fullpath'));

% Add src
addpath(genpath(fullfile(cDirThis, '..', 'src')));

% 'u16TcpipPort', 4001 ...

mmc103 = micronix.MMC103(...
    'cConnection', micronix.MMC103.cCONNECTION_TCPCLIENT, ...
    'cTcpipHost', '192.168.0.4', ...
    'u16TcpipPort', 4001 ...
);

mmc103.init();
mmc103.connect();
mmc103.firmwareVersion(uint8(1))
mmc103.clearErrors()
mmc103.disconnect();
% mmc103.comm.Terminator


% mmc103.disconnect();






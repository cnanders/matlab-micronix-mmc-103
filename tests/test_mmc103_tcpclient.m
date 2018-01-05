[cDirThis, cName, cExt] = fileparts(mfilename('fullpath'));

% Add src
addpath(genpath(fullfile(cDirThis, '..', 'src')));

% 'u16TcpipPort', 4001 ...

mmc = micronix.MMC103(...
    'cConnection', micronix.MMC103.cCONNECTION_TCPCLIENT, ...
    'cTcpipHost', '192.168.0.2', ...
    'u16TcpipPort', 4001 ...
);

mmc.init();
mmc.connect();
mmc.getFirmwareVersion(uint8(1))
mmc.getStatusByte(1)
mmc.getIsStopped(1)

% mmc.getAcceleration(1)
% mmc.clearErrors()
% mmc.disconnect();
% mmc.comm.Terminator


% mmc.disconnect();






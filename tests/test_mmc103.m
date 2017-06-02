[cDirThis, cName, cExt] = fileparts(mfilename('fullpath'));

% Add src
addpath(genpath(fullfile(cDirThis, '..', 'src')));

% 'u16TcpipPort', 4001 ...

%% Create the micronix.MMC103 instance
mmc103 = micronix.MMC103(...
    'cConnection', micronix.MMC103.cCONNECTION_TCPIP, ...
    'cTcpipHost', '192.168.0.2', ...
    'u16TcpipPort', 4001 ...
);

%% Initialize (create tcpip/tcpclient/serial)
mmc103.init();

%% Open connection to tcpip/tcpclient/serial)
mmc103.connect();



%% Get Firmware Version
mmc103.getFirmwareVersion(uint8(1))

%% Get position of axis 1 (mm)
fprintf(...
    'theoretical value of axis 1 = %1.3e\n', ...
    mmc103.getTheoreticalPosition(1)...
);
fprintf(...
    'encoder value of axis 1 = %1.3e\n', ...
    mmc103.getEncoderPosition(1)...
)
fprintf(...
    'encoder polarity of axis 1 = %u\n', ...
    mmc103.getEncoderPolarity(1) ...
)
fprintf(...
    'feedback mode of axis 1 = %u\n', ...
    mmc103.getFeedbackMode(1) ...
);

%% Move axis 1 to 1 mm
% mmc103.moveAbsolute(uint8(1), 1);



%{
mmc103.getStatusByte(1)
mmc103.getIsStopped(1)
mmc103.getAcceleration(1)
mmc103.clearErrors()
%}

%% Close connection to tcpip/tcpclient/serial
% mmc103.disconnect();







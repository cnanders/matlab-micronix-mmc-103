[cDirThis, cName, cExt] = fileparts(mfilename('fullpath'));

% Add src
addpath(genpath(fullfile(cDirThis, '..', 'src')));

% 'u16TcpipPort', 4001 ...

%% Create the micronix.MMC103 instance
mmc = micronix.MMC103(...
    'cConnection', micronix.MMC103.cCONNECTION_TCPIP, ...
    'cTcpipHost', '192.168.0.2', ...
    'u16TcpipPort', 4001 ...
);

%% Initialize (create tcpip/tcpclient/serial)
mmc.init();

%% Open connection to tcpip/tcpclient/serial)
mmc.connect();

%% Clear any bytes sitting in the output buffer
mmc.clearBytesAvailable()

%% Get Firmware Version
mmc.getFirmwareVersion(uint8(1))

%% Get position of axis 1 (mm)
fprintf(...
    'theoretical value of axis 1 = %1.3e\n', ...
    mmc.getTheoreticalPosition(1)...
);
fprintf(...
    'encoder value of axis 1 = %1.3e\n', ...
    mmc.getEncoderPosition(1)...
)
fprintf(...
    'encoder polarity of axis 1 = %u\n', ...
    mmc.getEncoderPolarity(1) ...
)

fprintf(...
    'feedback mode of axis 1 = %u\n', ...
    mmc.getFeedbackMode(1) ...
);


fprintf(...
    'encoder resolution of axis 1 = %1.3e um\n', ...
    mmc.getEncoderResolution(1) ...
);

fprintf(...
    'has axis 1 been homed since controller startup? %u\n', ...
    mmc.getHomed(1) ...
);

%% Initialize



%% Move axis 1 to 1 mm
% mmc.moveAbsolute(uint8(1), 1);



%{
mmc.getStatusByte(1)
mmc.getIsStopped(1)
mmc.getAcceleration(1)
mmc.clearErrors()
%}

%% Close connection to tcpip/tcpclient/serial
% mmc.disconnect();







[cDirThis, cName, cExt] = fileparts(mfilename('fullpath'));

% Add src
addpath(genpath(fullfile(cDirThis, '..', 'src')));

% 'u16TcpipPort', 4001 ...


cHost = '192.168.0.4';
cHost = '192.168.10.21';

mmc = micronix.MMC103(...
    'cConnection', micronix.MMC103.cCONNECTION_TCPCLIENT, ...
    'cTcpipHost', cHost, ...
    'u16TcpipPort', 4001 ...
);

mmc.init();
mmc.connect();
% mmc.readAndClearErrors(1);
mmc.clearBytesAvailable()
% mmc.clearErrors()
mmc.getFirmwareVersion(uint8(1)) % should be '#MMC-103.X1 v1.1.6' if not something is wrong.
%mmc.disconnect()
mmc.getEncoderPosition(1)
mmc.getEncoderPosition(1)
mmc.getEncoderPosition(2)


% mmc.disconnect()
% mmc.disconnect()

% mmc.reset() % Do this if there are problems with a queue of answers
% building up inside the MMC
% mmc.disconnect()
%{
mmc.getStatusByte(1)
mmc.getIsStopped(1)
mmc.getFeedbackMode(uint8(1))
%}


% SOME MANUAL COMMANDS DURING DEBUGGING WITH MATT

%{
mmc.write('1FBK0') % sets feedback mode of channel 1 to 0 (no feedback)
mmc.ioChar('1FBK?') % queries feedback mode
mmc.write('1VEL1.5') % sets velocity of channel 1 to 1.5 mm /s
mmc.write('1SAV') % saves all channel 1 settings
%}
% mmc.getAcceleration(1)
% mmc.clearErrors()
% mmc.disconnect();
% mmc.comm.Terminator

mmc.ioChar('1ENC?')
mmc.ioChar('1VEL?')


% mmc.disconnect();


%{
 mmc.ioChar('1REZ?')

ans =

    '#6000'
%}




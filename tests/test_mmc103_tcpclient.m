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
mmc.getAcceleration(1)
mmc.clearErrors()
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



%% How to fix if it gets stuck on negative limit.
%% CODE BELOW WORKS.  TESTED 2019.08.28 BY CHRIS.

% I found that the stage has a hard time moving from the negative limit to
% the positive limit with the configuration / velocity it has right now.
% It can move from the positive limit towards the negative limit OK but not
% the other way.  When issuing mmc.moveToPositiveLimit() , the controller
% overrides velocities / accellerations and uses defaults that work.  The
% trick is to use a combination of moveToPositiveLimit() and stopMotion()
% to stop it where you want.

%{
% The stage sometimes gets stuck trying to reach the negative limit. It
% can't get there. 

mmc.moveToPositiveLimit(1) %
mmc.home(1) %when on positive limit, home doesn't try to go to negative limit, which is unreachable

% This command moves to center M142 under the beam
mmc.moveAbsolute(1, -34.8)
%}



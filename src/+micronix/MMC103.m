classdef MMC103 < handle
    
    %MMC103 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        
        cCONNECTION_SERIAL = 'serial'
        cCONNECTION_TCPIP = 'tcpip'
        cCONNECTION_TCPCLIENT = 'tcpclient'
        
    end
    
    properties
        % {tcpip 1x1} tcpip connection 
        % MATLAB talks to nPort 5150A Serial Device Server over tcpip.
        % The nPort then talks to the MMC-103 using RS-485 BUS
        comm
        
    end
    
    properties (Access = private)
        
        % tcpip config
        % --------------------------------
        % {char 1xm} tcp/ip host
        cTcpipHost = '192.168.0.2'
        
        % {uint16 1x1} tcpip port NPort requires a port of 4001 when in
        % "TCP server" mode
        u16TcpipPort = uint16(4001)
        
        % The tcpip implementation can make use of fprintf() for writing
        % commands and fscanf() for reading commands since all of the data
        % is passed using ASCII format.  fprintf() converts an ASCII string
        % to an array of int8 (one int8 per character) and subsequently converts
        % each int8 to 8 bits (e.g., 00110100) to form the data packet.
        % Note that there is also a subtle thing with fprintf that it
        % formats the char you provide as %s\n (or optionally you can
        % provide a format) and replaces instances of \n with the
        % terminator byte
        %
        % fscanf() is a nice utility because while it is reading, it
        % continuously polls until it reads the terminator byte.
        %
        % The tcpclient implmentation must manually build the data packets
        % and manually poll for the termination byte because fprintf and
        % fscanf are not supported by tcpclient instances. 
        %
        % fwrite() and fread() write and read binary data and
        % fread does not do any polling.  This is good because
        % it lets us directly  create the data packets that are sent and
        % directly unpack the data packets that are received. 
        %
        % Writing:
        % During write commands, the binary version of the ASCII command
        % must be followed by a carriage return (13).
        % Optionally, it can be followed 10 13 (space + line feed +
        % carriage return).  Multiple write commands can be sent at
        % once
        %
        % Reading
        % The number of commands sent since the last read dictates
        % the number of responses that will be included in the next read.
        % Every response has a 10 (line feed) after it.  The last reaponse 
        % additionally has a carriage return (13) after it. I.E., the last
        % response has a 10 and a 13 after it. When a 13 is read, the data
        % read operation containing the result of every command since the
        % previous read is done.
        
        % {logical 1x1} use manually created binary data packets with tcpip 
        % uses fwrite instead of fprintf
        lManualPacket = false
        % {logical 1x1} use manual polling and reading of binary data with 
        % tcpip (uses fread in a while loop instead of fscanf)
        lManualPollAndRead = false
        
        % serial config
        % --------------------------------
        u16BaudRate = 38400;
        cPort = 'COM1'
        cTerminator = 'LF/CR';
        
        cConnection
        
        % When connection is serial(), 
        % ASCII 'CR' is equivalent to int value of 13
        
        
        u16InputBufferSize = uint16(2^15);
        u16OutputBufferSize = uint16(2^15);
        
        dTimeout = 5
    end
    
    methods
        
        function this = MMC103(varargin)
            
            this.cConnection = this.cCONNECTION_SERIAL;
            
            for k = 1 : 2: length(varargin)
                this.msg(sprintf('passed in %s', varargin{k}));
                if this.hasProp( varargin{k})
                    this.msg(sprintf('settting %s', varargin{k}));
                    this.(varargin{k}) = varargin{k + 1};
                end
            end
        end
        
        function init(this)
            
            switch this.cConnection
                case this.cCONNECTION_SERIAL
                    try
                        this.msg('init() creating serial instance');
                        this.comm = serial(this.cPort);
                        this.comm.BaudRate = this.u16BaudRate;
                        this.comm.Terminator = this.cTerminator;
                        % this.comm.InputBufferSize = this.u16InputBufferSize;
                        % this.comm.OutputBufferSize = this.u16OutputBufferSize;
                    catch ME
                        rethrow(ME)
                    end
                case this.cCONNECTION_TCPIP
                    try 
                        this.msg('init() creating tcpip instance');
                        this.comm = tcpip(this.cTcpipHost, this.u16TcpipPort);
                        this.comm.Terminator = 13; % carriage return
                        % Don't use Nagle's algorithm; send data
                        % immediately to the newtork
                        this.comm.TransferDelay = 'off'; 
                    catch ME 
                        rethrow(ME)
                    end
                case this.cCONNECTION_TCPCLIENT
                    try
                       this.msg('init() creating tcpclient instance');
                       this.comm = tcpclient(this.cTcpipHost, this.u16TcpipPort);
                    catch ME
                        rethrow(ME)
                    end
            end
            

        end
        
        function clearBytesAvailable(this)
            
            % This doesn't alway work.  I've found that if I overfill the
            % input buffer, call this method, then do a subsequent read,
            % the results come back all with -1.6050e9.  Need to figure
            % this out
            
            this.msg('clearBytesAvailable()');
            
            while this.comm.BytesAvailable > 0
                cMsg = sprintf(...
                    'clearBytesAvailable() clearing %1.0f bytes', ...
                    this.comm.BytesAvailable ...
                );
                this.msg(cMsg);
                fread(this.comm, this.comm.BytesAvailable);
            end
        end
        
        function connect(this)
            this.msg('connect()');
            switch this.cConnection
                case this.cCONNECTION_TCPCLIENT
                    % Do nothing
                otherwise
                    % tcpip and serial both need to be open with fopen 
                    try
                        fopen(this.comm); 
                    catch ME
                        rethrow(ME)
                    end
            end
            
            this.clearBytesAvailable();
        end
        
        function disconnect(this)
            this.msg('disconnect()');
            
            switch this.cConnection
                case this.cCONNECTION_TCPCLIENT
                    % Do nothing
                otherwise
                    try
                        fclose(this.comm);
                    catch ME
                        rethrow(ME);
                    end
            end
        end
        
        function delete(this)
            this.msg('delete()');
            this.disconnect();
        end
        
        function msg(this, cMsg)
            fprintf('MMC103 %s\n', cMsg);
        end
        
        function c = getFirmwareVersion(this, u8Axis)
            cCmd = sprintf('%uVER?', u8Axis);
            c = this.ioChar(cCmd);
        end
        
       
        
        
        
        function clearErrors(this)
            cCmd = '0CER';
            this.write(cCmd);
        end
                
        function setEncoderToDigital(this, u8Axis)
            cCmd = sprintf('%uEAD0', u8Axis);
            this.write(cCmd);
        end
        
        % {uint8 1x1} u8Axis - the axis
        % {uint8 1x1} u8Val [0, 1, 2, 3] - see Chapter 4.1 of the manual
        % 0 = traditional open loop tries to achieve user-set velocity
        % 1 = another version of open loop that never stresses the motor
        % and uses an easier velocity
        % 2 = closed loop to `theoretical_pos` always using mode 1 (no
        % stress on motor) during moves
        % 3 = closed loop using user-set velocity during moves
        
        function setFeedbackMode(this, u8Axis, u8Val)
            cCmd = sprintf('%uFBK%u', u8Axis, u8Val);
            this.write(cCmd);
        end
        
        function d = getFeedbackMode(this, u8Axis)
            cCmd = sprintf('%uFBK?', u8Axis);
            d = this.ioDouble(cCmd);
        end
        
        function setEncoderToAnalog(this, u8Axis)
            cCmd = sprintf('%uEAD1', u8Axis);
            this.write(cCmd);
        end
        
        function setEncoderPolarity(this, u8Axis, u8Val)
            cCmd = sprintf('%uEPL%u', u8Axis, u8Val);
            this.write(cCmd);
        end
        
        function setEncoderPolarityNormal(this, u8Axis)
            cCmd = sprintf('%uEPL0', u8Axis);
            this.write(cCmd);
        end
        
        function setEncoderPolarityReverse(this, u8Axis)
            cCmd = sprintf('%uEPL1', u8Axis);
            this.write(cCmd);
        end
        
        function setFeedbackOpenLoop(this, u8Axis)
            cCmd = sprintf('%uFBK0', u8Axis);
            this.write(cCmd);
        end
        
        function setFeedbackCleanOpenLoop(this, u8Axis)
            cCmd = sprintf('%uFBK1', u8Axis);
            this.write(cCmd);
        end
        
        function setFeedbackCleanOpenLoopMoveClosedLoopDecel(this, u8Axis)
            cCmd = sprintf('%uFBK2', u8Axis);
            this.write(cCmd);
        end
        
        function setFeedbackClosedLoop(this, u8Axis)
            cCmd = sprintf('%uFBK3', u8Axis);
            this.write(cCmd);
        end
        
        function setSoftLimitNegativePosition(this, u8Axis, dVal)
            cCmd = sprintf('%uTLN%1.6f', u8Axis, dVal);
            this.write(cCmd);
        end
        
        function setSoftLimitPositivePosition(this, u8Axis, dVal)
            cCmd = sprintf('%uTLP%1.6f', u8Axis, dVal);
            this.write(cCmd);
        end
        
        function setHomeToNegativeLimit(this, u8Axis)
            cCmd = sprintf('%uHCG0', u8Axis);
            this.write(cCmd);
        end
        
        function setHomeToPositiveLimit(this, u8Axis)
            cCmd = sprintf('%uHCG1', u8Axis);
            this.write(cCmd);
        end
        
        function c = getHomePosition(this, u8Axis)
            cCmd = sprintf('%uHCG?', u8Axis);
            c = this.ioChar(cCmd);
        end
        
        
        function d = getSoftLimitNegativePosition(this, u8Axis)
            cCmd = sprintf('%uTLN?', u8Axis);
            d = this.ioDouble(cCmd);
        end
        
        function d = getSoftLimitPositivePosition(this, u8Axis)
            cCmd = sprintf('%uTLP?', u8Axis);
            d = this.ioDouble(cCmd);
        end
        
        function home(this, u8Axis)
            cCmd = sprintf('%uHOM', u8Axis);
            this.write(cCmd);
        end
        
        % turn the motor current flow “Off” or “On” for a specified axis.
        % Turning the motor current off will cause the piezo to relax and
        % the stage will shift slightly.
        function setMotorOff(this, u8Axis)
            cCmd = sprintf('%uMOT0', u8Axis);
            this.write(cCmd);
        end
        
        % turn the motor current flow “Off” or “On” for a specified axis.
        % Turning the motor current off will cause the piezo to relax and
        % the stage will shift slightly.
        function setMotorOn(this, u8Axis)
            cCmd = sprintf('%uMOT1', u8Axis);
            this.write(cCmd);
        end
        
        % @param {double 1x1} dVal - mm (deg if rotary)
        function moveAbsolute(this, u8Axis, dVal)
            cCmd = sprintf('%uMVA%1.6f', u8Axis, dVal);
            this.write(cCmd);
        end
        
        function moveRelative(this, u8Axis, dVal)
            cCmd = sprintf('%uMVR%1.6f', u8Axis, dVal);
            this.write(cCmd);
        end
        
        
        function c = getErrors(this, u8Axis)
            cCmd = sprintf('%uERR?', u8Axis);
            c = this.ioChar(cCmd);
        end
        
        function d = getTheoreticalPosition(this, u8Axis)
            cCmd = sprintf('%uPOS?', u8Axis);
            c = this.ioChar(cCmd);
            % returned format: #theoretical_pos,encoder_pos
            % strip leading '#' character
            c = c(2:end);
            cecValues = strsplit(c, ',');
            d = str2double(cecValues{1});
        end
        
        function d = getEncoderPosition(this, u8Axis)
            cCmd = sprintf('%uPOS?', u8Axis);
            c = this.ioChar(cCmd);
            % returned format: #theoretical_pos,encoder_pos
            % strip leading '#' character
            c = c(2:end);
            cecValues = strsplit(c, ',');
            d = str2double(cecValues{2});
        end
        
        function d = getEncoderPolarity(this, u8Axis)
            cCmd = sprintf('%uEPL?', u8Axis);
            d = this.ioDouble(cCmd);
        end
        
        function d = getEncoderResolution(this, u8Axis)
            cCmd = sprintf('%uENC?', u8Axis);
            d = this.ioDouble(cCmd);
        end
        
        function saveSettings(this, u8Axis)
            cCmd = sprintf('%uSAV', u8Axis);
            this.write(cCmd);
        end
        
        function stopMotion(this, u8Axis)
            cCmd = sprintf('%uSTP', u8Axis);
            this.write(cCmd);
        end
        
        % {double 1x1} dVal - velocity mm/s (deg/s for rotary)
        function setVelocity(this, u8Axis, dVal)
            cCmd = sprintf('%uVEL%1.3f', u8Axis, dVal);
            this.write(cCmd);
        end
        
        function d = getVelocity(this, u8Axis)
            cCmd = sprintf('%uVEL?', u8Axis);
            d = this.ioDouble(cCmd);
        end
        
        % {return logical 1x1} true if the stage thinks it has been homed
        % On startup, returns false.  Issue HOM command to home. The ZRO
        % command resets the value of HOM? to false always.
        
        function l = getHomed(this, u8Axis)
            cCmd = sprintf('%uHOM?', u8Axis);
            d = this.ioDouble(cCmd);
            l = logical(d);
        end
        
        function setCurrentPositionAsZero(this, u8Axis)
            cCmd = sprintf('%uZRO', u8Axis);
            this.write(cCmd);
        end
        
        % {double 1x1} dVal - acceleration mm/s/s (deg/s/s for rotary)
        % 000.001 to (500.000 mm/s/s [degrees/s/s]) | AMX
        function setAcceleration(this, u8Axis, dVal)
            cCmd = sprintf('%uACC%1.6f', u8Axis, dVal);
            this.write(cCmd);
        end
        
        function d = getAcceleration(this, u8Axis)
            cCmd = sprintf('%uACC?', u8Axis);
            d = this.ioDouble(cCmd);
        end
        
        % {double 1x1} dVal - deceleration mm/s/s (deg/s/s for rotary)
        % 000.001 to (500.000 mm/s/s [degrees/s/s]) | AMX
        function setDeceleration(this, u8Axis, dVal)
            cCmd = sprintf('%uDEC%1.6f', u8Axis, dVal);
            this.write(cCmd);
        end
        
        function d = getDeceleration(this, u8Axis)
            cCmd = sprintf('%uDEC?', u8Axis, dVal);
            d = this.ioDouble(cCmd);
        end
        
        function restoreFactoryDefaults(this, u8Axis)
            cCmd = sprintf('%uDEF', u8Axis);
            this.write(cCmd);
        end
        
        function c = readAndClearErrors(this, u8Axis)
            cCmd = sprintf('%uERR', u8Axis);
            c = this.ioChar(cCmd);
        end
        
        function moveToNegativeLimit(this, u8Axis)
            cCmd = sprintf('%uMLN', u8Axis);
            this.write(cCmd);
        end
        
        
        function moveToPositiveLimit(this, u8Axis)
            cCmd = sprintf('%uMLP', u8Axis);
            this.write(cCmd);
        end
        
        % @return {char 1x8} - returns a char representation af a byte in
        % binary.  Each bit is a flag for a property of the axis.  See
        % documentation.  E.g. '10011000'
        function c = getStatusByte(this, u8Axis)
            cCmd = sprintf('%uSTA?', u8Axis);
            c = this.ioChar(cCmd);
            % Returns ASCII represention of a uint8, preceeded by the 
            % number symbol, e.g., '#199'.
            % Strip the pound symbol
            c = c(2:end);
            % Convert the char to double, then to int, then to binary string
            % Each bit is a flag for a specific property
            c = dec2bin(uint8(str2double(c)), 8);
        end
        
        % Determine if an axis is stopped
        % @return {logical 1x1} - true if axis is stopped
        function l = getIsStopped(this, u8Axis)
            % Use bit 3 (bit start at 0) from the status byte
            cStatusByte = this.getStatusByte(u8Axis);
            l = logical(str2double(cStatusByte(5)));
        end
        
        % Send a command and get the result back as ASCII
        function c = ioChar(this, cCmd)
            this.write(cCmd)
            c = this.read();
        end
        
        % Write an ASCII command to  
        % Create the binary command packet as follows:
        % Convert the char command into a list of uint8 (decimal), 
        % concat with the first terminator: 10 (base10) === 'line feed')
        % concat with the second terminator: 13 (base10)=== 'carriage return') 
        % write the command to the tcpip port (the nPort 5150A)
        % using binary (each uint8 is converted to stream of 8 bits, I think)
        function write(this, cCmd)
            
            % this.msg(sprintf('write %s', cCmd))
            switch this.cConnection
                case this.cCONNECTION_TCPCLIENT
                    u8Cmd = [uint8(cCmd) 10 13];
                    write(this.comm, u8Cmd);
                case  this.cCONNECTION_TCPIP
                    if this.lManualPacket
                        u8Cmd = [uint8(cCmd) 10 13];
                        fwrite(this.comm, u8Cmd);
                    else
                        % default format for fprintf is %s\n and 
                        % fprintf replaces instances of \n by the terminator
                        % then fprintf converts each ASCII character to its
                        % 8-bit representation to create the data packet
                        fprintf(this.comm, cCmd);
                    end
                case this.cCONNECTION_SERIAL
                    fprintf(this.comm, cCmd);
            end
                    
        end
    end
    
    
    methods (Access = protected)
        
        
        
        % Send a command and format the result as a double
        function d = ioDouble(this, cCmd)
            c = this.ioChar(cCmd);
            % strip leading '#' char
            c = c(2:end);
            d = str2double(c);
        end
        
        
        
        % Read until the terminator is reached and convert to ASCII if
        % necessary (tcpip and tcpclient transmit and receive binary data).
        % @return {char 1xm} the ASCII result
        
        function c = read(this)
            
            switch this.cConnection
                case this.cCONNECTION_TCPCLIENT
                    u8Result = this.readToTerminator(int8(13));
                    % remove line feed and carriage return terminator
                    u8Result = u8Result(1 : end - 2);
                    % convert to ASCII (char)
                    c = char(u8Result);
                case this.cCONNECTION_TCPIP
                    if this.lManualPollAndRead
                        u8Result = this.freadToTerminator(int8(13));
                        % remove line feed terminator of single return value
                        % and remove carriage return terminator
                        u8Result = u8Result(1 : end - 2);
                        % convert to ASCII (char)
                        c = char(u8Result);
                    else
                        c = fscanf(this.comm);
                        c = c(1 : end - 2);
                        % uint8(c)
                    end
                case this.cCONNECTION_SERIAL
                    c = fscanf(this.comm);
            end
        end
        
        % We want to do writes with fwrite() and reads with fread() because
        % it allows us to construct the binary data packet.  fprintf() and
        % fscanf() do some weird shit with replacing \n by the terminator
        % and stuff that can lead to problems.  With fwrite() and fread(),
        % you have full control over what is sent and received.
        %
        % fread(), if not supplied with a number of bytes, will attempt to
        % read tcpip.InputBufferSize bytes.  In general, Never call fread()
        % without specifying the number of bytes because it will read for
        % tcpip.Timeout seconds
        %
        % The MMC-103 documentation does not say how many bytes are
        % returned by each command so we do not know a-priori how many
        % bytes to wait for in the input buffer.  If we did we could have a
        % while loop similar to while (this.comm.BytesAvailable <
        % bytesRequired) that polls BytesAvailable and then only issues the
        % fread(this.comm, bytesRequired) once those bytes are availabe.
        %
        % The alternate approach, below is more of a manual
        % implementatation of what fscanf() does, but for binary data.   As
        % bytes become available, read them in and check to see if the
        % terminator character has been found.  Once the terminator is
        % reached, the read is complete.
        % @return {uint8 1xm} 

        function u8 = freadToTerminator(this, u8Terminator)
            
            lTerminatorReached = false;
            u8Result = [];
            while(~lTerminatorReached)
                if (this.comm.BytesAvailable > 0)
                    
                    cMsg = sprintf(...
                        'freadToTerminator reading %u bytesAvailable', ...
                        this.comm.BytesAvailable ...
                    );
                    this.msg(cMsg);
                    % {uint8 mx1} fread returns a column, need to transpose
                    % when appending below.
                    u8Val = fread(this.comm, this.comm.BytesAvailable);
                    % {uint8 1x?}
                    u8Result = [u8Result u8Val'];
                    % search new data for terminator
                    u8Index = find(u8Val == u8Terminator);
                    if ~isempty(u8Index)
                        lTerminatorReached = true;
                    end
                end
                pause(0.01)
            end
            
            u8 = u8Result;
            
        end
        
        % See freadToTerminator
        % Direct analog of freadToTerminator but with read() which works
        % with tcpclient instances rather than tcpip instances
        function u8 = readToTerminator(this, u8Terminator)
            
            lTerminatorReached = false;
            u8Result = [];
            idTic = tic;
            while(~lTerminatorReached && ...
                   toc(idTic) < this.dTimeout )
                if (this.comm.BytesAvailable > 0)
                    
                    cMsg = sprintf(...
                        'readToTerminator reading %u bytesAvailable', ...
                        this.comm.BytesAvailable ...
                    );
                    this.msg(cMsg);
                    % Append available bytes to previously read bytes
                    
                    % {uint8 1xm} 
                    u8Val = read(this.comm, this.comm.BytesAvailable);
                    % {uint8 1x?}
                    u8Result = [u8Result u8Val];
                    % search new data for terminator
                    u8Index = find(u8Val == u8Terminator);
                    if ~isempty(u8Index)
                        lTerminatorReached = true;
                    end
                end
            end
            
            u8 = u8Result;
            
        end
        
        function l = hasProp(this, c)
            
            l = false;
            if ~isempty(findprop(this, c))
                l = true;
            end
            
        end
        
    end
    
end


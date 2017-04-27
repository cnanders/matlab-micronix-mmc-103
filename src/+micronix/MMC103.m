classdef MMC103 < handle
    
    %MMC103 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % {tcpip 1x1} tcpip connection 
        % MATLAB talks to nPort 5150A Serial Device Server over tcpip.
        % The nPort then talks to the MMC-103 using RS-485 BUS
        c
        
    end
    
    properties (Access = private)
        
        % {char 1xm} tcp/ip host
        cTcpipHost = '192.168.0.2'
        
        % {uint16 1x1} tcpip port network control uses telnet port 23
        u16TcpipPort = uint16(23)
        
        u16InputBufferSize = uint16(2^15);
        u16OutputBufferSize = uint16(2^15);
        
       
        
    end
    
    methods
        
        function this = MMC103(varargin)
            
            for k = 1 : 2: length(varargin)
                this.msg(sprintf('passed in %s', varargin{k}));
                if this.hasProp( varargin{k})
                    this.msg(sprintf('settting %s', varargin{k}));
                    this.(varargin{k}) = varargin{k + 1};
                end
            end
        end
        
        function init(this)
            
            this.c = tcpip(this.cTcpipHost, this.u16TcpipPort);
            % this.c.BaudRate = this.u16BaudRate;
            this.c.InputBufferSize = this.u16InputBufferSize;
            this.c.OutputBufferSize = this.u16OutputBufferSize;

        end
        
        function clearBytesAvailable(this)
            
            % This doesn't alway work.  I've found that if I overfill the
            % input buffer, call this method, then do a subsequent read,
            % the results come back all with -1.6050e9.  Need to figure
            % this out
            
            this.msg('clearBytesAvailable()');
            
            while this.c.BytesAvailable > 0
                cMsg = sprintf(...
                    'clearBytesAvailable() clearing %1.0f bytes', ...
                    this.c.BytesAvailable ...
                );
                this.msg(cMsg);
                fread(this.c, this.c.BytesAvailable);
            end
        end
        
        function connect(this)
            this.msg('connect()');
            try
                fopen(this.c); 
            catch ME
                
            end
            this.clearBytesAvailable();
        end
        
        function disconnect(this)
            this.msg('disconnect()');
            try
                fclose(this.c);
            catch ME
            end
        end
        
        function delete(this)
            this.msg('delete()');
            this.disconnect();
            
        end
        
        function msg(this, cMsg)
            fprintf('MMC103 %s\n', cMsg);
        end
        
    end
    
    
    methods (Access = protected)
        
        
        function l = hasProp(this, c)
            
            l = false;
            if ~isempty(findprop(this, c))
                l = true;
            end
            
        end
        
    end
    
end


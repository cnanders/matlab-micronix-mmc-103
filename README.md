# MATLAB Micronix MMC 103

MATLAB communication With Micronix MMC-103 3-Axis Piezo Motor Controller.  The MMC-103 contains a FTDI Board that supports two interfaces: USB 2.0 and RS-485.  Below is a list of a few different options for communicating between MATLAB and the FTDI board inside the MMC-103

## Option 1 (simplest, requires USB connection)

### Overview
1. MATLAB -> FTDI middleware (VCP) using `MATLAB.serial()`
2. FTDI Middleware -> MMC-103 using USB


### Details
- USB cable between MATLAB client and MMC-103
- Middleware (driver) on client converts USB to Virtual COM Port
- MATLAB uses `serial()` to communicate with middleware Virtual COM Port.  Middleware communicates with MMC-103 over USB.


FTDI provides a [USB -> Virtual COM Port (VCP) (RS-232) driver](http://www.ftdichip.com/Drivers/VCP.htm) available for macOS and Windows.  macOS >= 10.9 (Mavericks) ships with included built-in partial support for some FTDI devices in VCP mode.  macOS >= 10.11 (El Capitan) has even better support.  

[Check to see if your OS automatically creates a VCP for the FTDI without installing the driver](https://github.com/cnanders/matlab-npoint-lc400#terminal)

## Option 2

### Overview
1. MATLAB -> NPort using `MATLAB.tcpip()`
2. NPort -> MMC-103 using RS-485

### Details
- Extra piece of hardware called a Serial Device Server (e.g., [NPort 5150A](http://www.moxa.com/product/NPort_5100A.htm))
- RS-485 cable between Serial Device Server and MMC-103
- Ethernet cable between Serial Device Server and local network
- Client connects to local network
- MATLAB uses `tcpip()` to communicate with Serial Device Server over local network

### Trial and Error Notes

- NPort Configuration "Data Packing Parameter" -> Delimiter 1 and Delimiter 2 must be set to the hex values of `\n` (0x0A) and `\r\` (0x0D), respectively
- When receiving data, each line of data will be followed by the new line terminating character [\n] *except* the final line (or first line if final line is first line!) which ends in the new line *and* carriage return terminating characters [\n\r]
- To send data to the controller, enter the desired commands in the command line followed by the new line and carriage return terminating characters [\n\r], **OR** just the carriage return terminating character [\r] (ASCII === 'CR', int === 13)


## Option 3

### Overview
1. MATLAB -> NPort middleware (VCP) using `MATLAB.serial()`
2. NPort Middlware -> NPort using tcpip
3. NPort -> MMC-103 using RS-485

### Details
- Extra piece of hardware called a Serial Device Server (e.g., [NPort 5150A](http://www.moxa.com/product/NPort_5100A.htm))
- RS-485 cable between Serial Device Server and MMC-103
- Ethernet cable between Serial Device Server local network
- Client connects to local network
- Middleware software converts ethernet-conneciton to Serial Device Server into Virtual COM Port
- MATLAB uses `serial()` to communicate with middleware Virtual COM Port.  Middleware communicates to Serial Device Server over local network

#### Gotchas

- The NPort Middleware (NPort Administrator) COM mapping must be configured to use a baud rate of 38400 and MATLAB's `serial()` must be configured to use a baud rate of 38400.  38400 is the baud rate that the FTDI board in the MMC-103 uses. If these are not both set to 38400, communication **won't work**.
- MATLAB's `serial()` must be configured with a terminator of `LF/CR`.  
    - `CR/LF` (the transpose) **won't work**
    - Do not include the `\n\r` [new line, carriage return] terminator in commands as the MMC documentation suggests. MATLAB's `serial()` handles termination characters in the background.
    - DO: `fprintf(this.serial, '1VER?')`
    - DONT: `fprintf(this.serial, '1VER \n\r')`


# STOP HERE

### USB 2.0 with MATLAB `serial()` (uses Middleware)

Overview


### RS-485 with MATLAB `serial()` (uses Middleware)

Overview


### RS-485 with MATLAB `tcpip()`

Overview

  
Great Resource
[RS-232, RS-422, RS-485 Serial Communication General Concepts](http://www.ni.com/white-paper/11390/en/)



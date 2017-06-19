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


# Notes from Commissioning With Real Hardware

## Encoder Resolution / EDV

The MMC-103 shipped with the encoder resolution `1ENC?` set to 2 nm. The encoder was configured for 10 nm so there was a 5X error between `theoretical_pos` and `encoder_pos` (see below).  Updating the encoder resoltution 10 removed the discrepancy between `theoretical_pos` and `encoder_pos`.  However, it was later found that this change of settings introduced another error.  The stage would regularly lose it’s encoder during `1HOM` home commands.  The solution to this was to modify a hidden, undocumented setting `EDV`, only accessible once logged with the micronix-provided administrative credentials.  (Can login using `0LCK23982` command - the preceeding “0” is for all channels). The `EDV` setting has something to do with reading the encoder value (possibly earliest data valid?).  It was increased from the shipped setting of 8000 to 50000.  Matt from Micronix was the one that suggested this change after we reproducibly lost the encoder during `1HOM` command.  Matt also said that this setting is supposed to scale linearly with encoder resolution (`ENC`) so after the resolution was increased from 2 nm to 10 nm, the `EDV` value should also be scaled 5X from 8000 to 40000 (but it was set even higher to 50000).

## POS? Query: `theoretical_pos` vs. `encoder_pos`

The `POS?` query returns two values: `theoretical_pos`, `encoder_pos`.  This can be pretty confusing so let me explain.  Whenever the MMC-103 controller is power-cycled, the current stage position is set to a `theoretical_pos` value of zero.  

The controller supports two styles of move commands: absolute and relative.  These both update `theoretical_pos` stored within the MMC-103 controller to a new value when issued. 

E.g., if `theoretical_pos` is -5 and a `move_rel = +5` command is sent, `theoretical_pos` is updated to 0 and the stage is commanded to move for an amount of time based on the delta of +5 mm (see more below)  

E.g., if `theoretical_pos` is -5 and a `move_abs = +5` command is sent, `theoretical_pos` is updated to +5 and the stage is commanded to move for an amount of time based on the delta of +10 mm (see more below)

The "gotcha" is that, *in general, the amount a stage moves in open loop for a commanded change in `theoritcal_pos` move is never the right amount*

Based on the move command that is issued, `theoretical_pos` changes by some amount, `delta_theoretical_pos`.  The controller divides `delta_theoretical_pos` by the velocity it thinks the stage can move to get a "time of move" and then commands the stage to move for `time_of_move` seconds.  The amount the stage actually moves in `time_of_move` seconds will most likely be less than `delta_theoretical_pos` mm. 

## Feedback Mode: Open Loop vs Closed Loop

If you want the stage to move to the value of `theoretical_pos` whenever `theoretical_pos` changes, you need to turn on closed loop operation.  See section 4.1 of the manual.

Example:
1. issue a "set axis 1 `theoretical_pos` to zero at current axis 1 pos" command: `1ZRO`
2. issue a "move axis 1 relative by +5 mm" command: `1MVR5`
3. wait for move to complete
4. issue a "get position of axis 1" command (`1POS?`)

You will find that `theoretical_pos` will be updated to 5 and the `encoder_pos` will be a value between 0 and 5, most likeley not the desired 5 mm, which means the stage *did not* actually move +5 mm.

If you now set the feedback mode to 2, for "closed loop that does not stress the motor ever", the stage will immediately start moving until the `encoder_pos` reaches a value within the "closed loop deadband" (closed loop locking resolution) of `theoretical_pos`.  Nice.

### Gotchas


- Issuing a "move to positive limit" command **always forces** the feedback mode to 0 (open loop) before it executes.  Feedback mode should be reset to its pre-command value after command finishes.
- Issuing a "move to negative limit" command **always forces** the feedback mode to 0 (open loop) before it executes.
- If a `theoretical_pos` value is outside of the allowed possible `encoder_pos` values when closed loop mode is entered, the controller will indefinitely attempt to drive the stage such that `encoder_pos` matches `theoretical_pos`.  This will keep the motor on indefinitely, and will most likely damage the motor. The only solution is to unplug the controller.  
- **Never go into a closed loop mode when `theoretical_pos` is an unobtainable value.**  After  "move to positive limit" or "move to negative limit" commands, the `theoretical_pos` value is almost always an unobtainable value

### Recommendations For Closed Loop

The recommended solution is to set soft limits just inside the positive and negative limits.  This makes it so that `theoretical_pos` can never go outside of allowed `encoder_pos` values.  But you only wnat do do this once you know the `encoder_pos` values at the physical limits.  Procedure:

1. issue a "home" axis 1 command (`1HOM`). 
2. issue the "set `theoretical_pos` and `encoder_pos` to zero at the current position of axis 1" (`1ZRO`)
3. **make sure** you are in one of the two open loop move modes (`1FBK0` or `1FBK1`)
3. issue the "move to positive limit" command (`1MLP`) (Move to Limit Positive) **BE ADVISED issuing this command always resets the feedback mode to 0 (open loop) before executing and the feedback mode is not switched back after.**
4. issue a "get encoder position of axis 1" command (`1POS?`)
5. record the value of `encoder_pos` and use it to set the positive limit.  Note that the value of `theoretical_pos` will probably be bigger than `encoder_pos`.
9. issue the "set positive software limit" command (`1TLPxxx`) where `xxx` is the value from 8 less a few um
6. issue the "move to negative limit" command (`1MLN`) (Move to Limit Negative) **BE ADVISED issuing this command always resets the feedback mode to 0 (open loop)before executing and the feedback mode is not switched back after.**
7. issue a "get position of axis 1" command (`1POS?`)
8. record the value of `encoder_pos` set the negative limit
9. issue the "set negative software limit" command (`1TLNxxx`) where `xxx` is the value from 8 less a few um
10. issue the "save axis settings" command (`1SAV`)


## Recommended Initialization / Operation Mode

Any time the MMC-103 is power cycled, the following set of commands is recommended.

1. issue a "home" axis 1 command (`1HOM`).  This does one of two things:
  1. If `encoder_pos` is positive, it moves towards negative limit and stops when it crosses the central "zero" index mark on the scale.
  2. If `encoder_pos` is negative, it moves towards the negative limit, eventually reaches the negative limit, then goes back towards the positive limit and stops when it crosses the central "zero" index mark on the scale
2. issue the "set `theoretical_pos` to zero at the current position of axis N".  This sets `theoretical_pos` to zero when the stage is actually at its "zero" index on the scale.  Nice.
3. issue the "set feedback mode to 2" commmand so that it goes into "closed loop that does not stress the motor ever" mode.


## Checking Encoder Polarity

To check encoder polarity:
1. issue the "set `theoretical_pos` to zero at the current position of axis 1" command (`1ZER` command to). 
2. issue a "move axis 1 relative + 5 mm" command (`1MVR5`).  
3. wait for move to complete
4. issue a "get position of axis 1" command (`1POS?`)

You will find that `theoretical_pos` will be updated to 5 and the `encoder_pos` will be some other value, mosts likeley not 5, that corresponds to the amount the stage physically moved during the move.  If the sign of `theoretical_pos` and `encoder_pos` are not the same, you need to flip the polaraity of the encoder of that axis

1. get the current polarity `1EPL?` (returns 0 [default] or 1)
2. set the polarity to the opposite value using `1EPL1` or `1EPL0`

## How To Check For Missing Counts

The interpolator has colored LED to indicate signal strength.  Send the stage to one limit and then to the other limit watching the signal strength LED color.  It should stay green the entire time.  If it turns yellow, orange, or red at any point, there is a good chance you are loosing encoder counts at those stage positions.

## HOM

Whenever the `1HOM` command is issued, it resets the "if homed since last startup" to zero.  The `1HOM?` query is available during the homing routing and returns zero during the home routine

## ZRO

Whenever the `ZRO` command is issued, it resets "if homed since last startup" to zero

Whereever the stage is when the controller is turned on - it sets the encoder to zero at that location.








# STOP HERE

### USB 2.0 with MATLAB `serial()` (uses Middleware)

Overview


### RS-485 with MATLAB `serial()` (uses Middleware)

Overview


### RS-485 with MATLAB `tcpip()`

Overview

  
Great Resource
[RS-232, RS-422, RS-485 Serial Communication General Concepts](http://www.ni.com/white-paper/11390/en/)



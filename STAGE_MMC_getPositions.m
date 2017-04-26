function [x y z] = STAGE_MMC_getPositions(stages)
%This function will return the x, y and z position of the stage. [um] 

send_command = [stages.axis.x ' ' stages.commands.mmc_current_position ';'];
[t_data_x] = STAGE_MMC_RESPONSE(stages, send_command);

send_command = [stages.axis.y ' ' stages.commands.mmc_current_position ';'];
[t_data_y] = STAGE_MMC_RESPONSE(stages, send_command);

send_command = [stages.axis.z ' ' stages.commands.mmc_current_position ';'];
[t_data_z] = STAGE_MMC_RESPONSE(stages, send_command);

[t_x, data_x] = parse_position(t_data_x);
[t_y, data_y] = parse_position(t_data_y);
[t_z, data_z] = parse_position(t_data_z);

x = data_x/stages.convert;
y = data_y/stages.convert;
z = data_z/stages.convert;


function [pos, enc_pos] = parse_position(str)
pos = 0.0;
enc_pos = 0.0;
if (length(str) > 0)
    if (str(1) == '#')
        t_str = strtrim(str(2:end));
        values = textscan(t_str, '%s', 'delimiter', ',');
        pos = str2double(values{1}{1});
        enc_pos = str2double(values{1}{2});
    end
end


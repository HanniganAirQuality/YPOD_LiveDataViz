%% Header
% @project  PBL Live Visualization YPOD Data
%
% @file     LiveVis_RETIGO.m
% @author   Percy Smith, percy.smith@colorado.edu   
% @brief    Firmware meant to visualize POD data live! 
%
% @date     September 20, 2024
% @version  3.5.0
% @log      Added a Car Emissions figure with CO, CO2, VOC, T, RH viz
%
%% Terminate
close all
clear 

%% SETTINGS
COMPORT = 'COM34';
    %if u don't know the com port, run serialportlist in command window

%% Initialize variables and establish serial connection
device = serialport(COMPORT,9600); %Change the com value here to whatever COM the pod corresponds to

configureTerminator(device, 'CR/LF')
flush(device)
configureCallback(device, 'terminator', @myCallback)
device.Timeout = 60;

%% Formatting Babey!!!
% Headers = ['Timestamp';... % Not counted bc it's timetable soon & REMOVED 'YPODID(-)', 'Longitude(deg)', 'Latitude(deg)',
%     'T_BME(degC)'; 'P_BME(mbars)'; 'T(degC)'; 'RH(%)';...
%     'Fig2600(bits)'; 'Fig2602(bits)'; 'Ozone(bits)'; 'CO(bits)'; 'CO_2(ppm)';...
%     'PM1.0(ug/m^3)'; 'PM2.5(ug/m^3)'; 'PM10.0(ug/m^3)'];
% Display_Header = ['DateTime';
%     'Temperature_{BME}';
%     'Pressure_{BME}';
%     'Temperature';
%     'Relative Humidity';
%     'Light VOC';
%     'Heavy VOC';
%     'Ozone (O_3)';
%     'Carbon Monoxide (CO)';
%     'Carbon Dioxide (CO_2)';
%     'PM 1.0';
%     'PM 2.5';
%     'PM 10.0';];
% Units = ['[DateTime]';
%         '[' + char(176) + 'C]';
%         '[mbars]';
%         '[' + char(176) + 'C]';
%         '[%RH]';
%         '[ADU]';
%         '[ADU]';
%         '[ADU]';
%         '[ADU]';
%         '[ppm]';
%         '[(ug)/(m^3)]';
%         '[(ug)/(m^3)]';
%         '[(ug)/(m^3)]';];
% 
% RETIGO = table(Headers, Display_Header, Units);
%     clear('Headers', 'Units', 'Display_Header');
% RETIGO

%% Callback
function myCallback(src, ~)
    plottype = 5;
        % [1] CO_2 only (10)
        % [2] VOC only (x2 channel) (6 7)
        % [3] PM 2.5 only  (12)
        % [4] SHOW ALL!!!!
        % [5] Car Exhaust Visualization +CO (9), VOC(6 7), 
    data = readline(src);
    src.UserData = [src.UserData; strsplit(data, ',')];
    switch plottype
        case 1
            CO2_ONLY(src);
        case 2
            VOC_2CHANNEL(src);
        case 3
            PM25_ONLY(src);
        case 4
            SHOW_ALL(src);
        case 5
            CAR_EMISSIONS(src);
        otherwise
            alternateGraph(src);
    end
end

%% CASE 1: CO2_ONLY
function CO2_ONLY(src)
    R = orderedcolors('reef');
    t = datetime(src.UserData(:,1)) + hours(1);
    CO_2 = str2double(src.UserData(:,10));
    tbl = timetable(t,CO_2);
        [MAX, ~] = max(tbl.CO_2);
            MAXLINE = sprintf('CO_2 max = %u ppm, ', MAX);
        [MIN, ~] = min(tbl.CO_2);
            MINLINE = sprintf('CO_2 min = %u ppm', MIN);
    TXT = '{\color[rgb]{' + string(R(4,1)) + ' ' + string(R(4,2)) + ' ' + string(R(4,3)) + '}' + MAXLINE  + MINLINE + '}';
    
    plot(tbl.t, tbl.CO_2, 'Color', R(4,:), 'LineWidth', 1.5);
        grid on;
    title('Carbon Dioxide Concentration vs. Time', 'FontSize', 18);
        subtitle(TXT, 'FontSize', 12);
        ylabel('Concentration of CO_2 [parts per million]', 'FontSize', 12);
            ylim([min(tbl.CO_2)*0.99 max(tbl.CO_2)*1.01]);
            xlim([min(t)-seconds(5), max(t)+seconds(5)]);
        legend('CO_2 [ppm]', 'Location', 'northwest');        
            % legend('CO_2 [ppm]', 'Location', 'northwest');
    refreshdata;
end

%% CASE 2: VOC_2CHANNEL 
function VOC_2CHANNEL(src)
    M = orderedcolors('meadow');
    t = datetime(src.UserData(:,1)) + hours(1);
    heavyVOC = str2double(src.UserData(:,6));
    lightVOC = str2double(src.UserData(:,7));
    tbl = timetable(t, heavyVOC, lightVOC);
        [heavyMAX, ~] = max(tbl.heavyVOC);
            heavyMAXLINE = sprintf('Heavy VOC max = %u [ADU], ', heavyMAX);
            text('Color', M(1,:));
        [heavyMIN, ~] = min(tbl.heavyVOC);
            heavyMINLINE = sprintf('Heavy VOC min = %u [ADU]', heavyMIN);
    heavyTXT = '{\color[rgb]{' + string(M(1,1)) + ' ' + string(M(1,2)) + ' ' + string(M(1,3)) + '}' + heavyMAXLINE  + heavyMINLINE + '}';
        [lightMAX, ~] = max(tbl.lightVOC);
            lightMAXLINE = sprintf('Light VOC max = %u [ADU], ', lightMAX);
        [lightMIN, ~] = min(tbl.lightVOC);
            lightMINLINE = sprintf('Light VOC min = %u [ADU]', lightMIN);
    lightTXT = '{\color[rgb]{' + string(M(2,1)) + ' ' + string(M(2,2)) + ' ' + string(M(2,3)) + '}' + lightMAXLINE  + lightMINLINE + '}';

    plot(tbl.t, tbl.lightVOC, 'Color', M(2,:), 'LineWidth', 1.5);
    hold on;
    plot(tbl.t, tbl.heavyVOC, 'Color', M(1,:), 'LineWidth', 1.5);
        grid on;
    title('Volatile Organic Compounds (VOCs): Figaro Signal vs. Time', 'FontSize', 18);
        subtitle(lightTXT + '  |  ' + heavyTXT, 'FontSize', 12);
        ylabel('VOC Signal [Analog-to-Digital Units]', 'FontSize', 12);
            % ylim([lightMIN-100 lightMAX+100]);
            xlim([min(t)-seconds(5), max(t)+seconds(5)]);
        legend({'Light VOC (Fig2602) [ADU]','Heavy VOC (Fig2600) [ADU]'}, 'Location', 'northwest');
    refreshdata;
end

%% CASE 3: PM25_ONLY
function PM25_ONLY(src)
    R = orderedcolors('reef');
    t = datetime(src.UserData(:,1)) + hours(1);
    PM25 = str2double(src.UserData(:,12));
    tbl = timetable(t,PM25);
        [MAX, ~] = max(tbl.PM25);
            MAXLINE = sprintf('PM 2.5 max = %u ug/m^3, ', MAX);
        [MIN, ~] = min(tbl.PM25);
            MINLINE = sprintf('PM 2.5 min = %u ug/m^3', MIN);
    TXT = '{\color[rgb]{' + string(R(6,1)) + ' ' + string(R(6,2)) + ' ' + string(R(6,3)) + '}' + MAXLINE  + MINLINE + '}';
    % tbl = retime(tbl, 'secondly', 'spline');

    plot(tbl.t, tbl.PM25, 'Color', R(5,:), 'LineWidth', 1.5);
        grid on;
    title('Particulate Matter (PM 2.5) Concentration vs. Time', 'FontSize', 18);
        subtitle(TXT, 'FontSize', 12);
        ylabel('Concentration of PM 2.5 [ug/m^3]', 'FontSize', 12);
            ylim([0 max(PM25)+10]);
            xlim([min(t)-seconds(5), max(t)+seconds(5)]);
        legend('PM 2.5 [ug/m^3]', 'Location', 'northwest');
    refreshdata;
end

%% CASE 4: SHOW_ALL
function SHOW_ALL(src)
    R = orderedcolors('reef');
    M = orderedcolors('meadow');
    t = datetime(src.UserData(:,1)) + hours(1);
    heavyVOC = str2double(src.UserData(:,6));
    lightVOC = str2double(src.UserData(:,7));
    CO_2 = str2double(src.UserData(:,10));
    PM25 = str2double(src.UserData(:,12));
    T = str2double(src.UserData(:,4));
    RH = str2double(src.UserData(:,5));
    tbl = timetable(t, heavyVOC, lightVOC, CO_2, PM25, T, RH);

    sz = 25;

    tiledlayout(5,2, 'TileSpacing', 'tight', 'Padding', 'tight');
    ax1 = nexttile(1);
        % TEMP_LIMS = [0.99*min(tbl.T) 1.01*min(tbl.T)]; 
        plot(tbl.t, tbl.T, 'k');
        hold on;
        scatter(tbl.t, tbl.T, sz, tbl.T,'filled');
        grid on;
        title('Temperature');
        ylabel('Temperature [\circC]');
        xlim([min(t)-seconds(5), max(t)+seconds(5)]);
        % ylim(TEMP_LIMS);
        colorbar(ax1);
        % clim(TEMP_LIMS);
        colormap(ax1, "hot");
    ax2 = nexttile(2);
        RH_LIMS = [0.99*min(tbl.RH) 1.01*max(tbl.RH)];
        plot(tbl.t, tbl.RH, 'k');
        hold on;
        scatter(tbl.t, tbl.RH, 20, tbl.RH,'filled');
        grid on;
        title('Relative Humidity');
        ylabel('Humidity [% RH]');
        xlim([min(t)-seconds(5), max(t)+seconds(5)]);
        ylim(RH_LIMS);
        colorbar(ax2);
        clim(RH_LIMS);
        colormap(ax2, sky);
    nexttile(4, [2 1]);
        plot(tbl.t, tbl.CO_2, 'Color', R(4,:), 'LineWidth', 1.5);
            grid on;
        title('Carbon Dioxide (CO_2)');
            ylabel('CO_2 [ppm]');
                ylim([min(tbl.CO_2)*0.99 max(tbl.CO_2)*1.01]);
                xlim([min(t)-seconds(5), max(t)+seconds(5)]);
            % legend('CO_2 [ppm]', 'Location', 'northwest');
    nexttile(8, [2 1]);
        plot(tbl.t, tbl.PM25, 'Color', R(5,:), 'LineWidth', 1.5);
            grid on;
        title('Particulate Matter 2.5');
            ylabel('PM 2.5 [ug/m^3]');
                ylim([0 max(PM25)+10]);
                xlim([min(t)-seconds(5), max(t)+seconds(5)]);
            % legend('PM 2.5 [ug/m^3]', 'Location', 'northwest');
    nexttile(3, [2 1]);
        plot(tbl.t, tbl.lightVOC, 'Color', M(2,:), 'LineWidth', 1.5);
            grid on;
        title('Light VOC Signal (Fig 2602)');
            ylabel('Signal [ADU]');
                ylim([min(tbl.lightVOC)*0.99 max(tbl.lightVOC*1.01)]);
                xlim([min(t)-seconds(5), max(t)+seconds(5)]);
            % legend('Light VOC [ADU]', 'Location', 'northwest');
    nexttile(7, [2 1]);
        plot(tbl.t, tbl.heavyVOC, 'Color', M(1,:), 'LineWidth', 1.5);
            grid on;
        title('Heavy VOC Signal (Fig 2600)');
            ylabel('Signal [ADU]');
                ylim([min(tbl.heavyVOC)*0.99 max(tbl.heavyVOC*1.01)]);
                xlim([min(t)-seconds(5), max(t)+seconds(5)]);
            % legend('Heavy VOC [ADU]', 'Location', 'northwest');
    refreshdata;
end

%% CASE 5: CAR_EMISSIONS
function CAR_EMISSIONS(src)
    R = orderedcolors('reef');
    M = orderedcolors('meadow');
    t = datetime(src.UserData(:,1)) + hours(1);
    heavyVOC = str2double(src.UserData(:,6));
    lightVOC = str2double(src.UserData(:,7));
    CO_2 = str2double(src.UserData(:,10));
    CO = str2double(src.UserData(:,9));
    T = str2double(src.UserData(:,4));
    RH = str2double(src.UserData(:,5));
    tbl = timetable(t, heavyVOC, lightVOC, CO_2, CO, T, RH);

    sz = 25;

    tiledlayout(5,2, 'TileSpacing', 'tight', 'Padding', 'tight');
    ax1 = nexttile(1);
        % TEMP_LIMS = [0.99*min(tbl.T) 1.01*min(tbl.T)]; 
        plot(tbl.t, tbl.T, 'k');
        hold on;
        scatter(tbl.t, tbl.T, sz, tbl.T,'filled');
        grid on;
        title('Temperature');
        ylabel('Temperature [\circC]');
        xlim([min(t)-seconds(5), max(t)+seconds(5)]);
        % ylim(TEMP_LIMS);
        colorbar(ax1);
        % clim(TEMP_LIMS);
        colormap(ax1, "hot");
    ax2 = nexttile(2);
        RH_LIMS = [0.99*min(tbl.RH) 1.01*max(tbl.RH)];
        plot(tbl.t, tbl.RH, 'k');
        hold on;
        scatter(tbl.t, tbl.RH, 20, tbl.RH,'filled');
        grid on;
        title('Relative Humidity');
        ylabel('Humidity [% RH]');
        xlim([min(t)-seconds(5), max(t)+seconds(5)]);
        ylim(RH_LIMS);
        colorbar(ax2);
        clim(RH_LIMS);
        colormap(ax2, sky);
    nexttile(4, [2 1]);
        plot(tbl.t, tbl.CO_2, 'Color', R(4,:), 'LineWidth', 1.5);
            grid on;
        title('Carbon Dioxide (CO_2)');
            ylabel('CO_2 [ppm]');
                ylim([min(tbl.CO_2)*0.99 max(tbl.CO_2)*1.01]);
                xlim([min(t)-seconds(5), max(t)+seconds(5)]);
            % legend('CO_2 [ppm]', 'Location', 'northwest');
    nexttile(8, [2 1]);
        plot(tbl.t, tbl.CO, 'Color', M(7,:), 'LineWidth', 1.5);
            grid on;
        title('Carbon Monoxide Signal (CO)');
            ylabel('Signal [ADU]');
                % ylim([0 max(CO)+10]);
                xlim([min(t)-seconds(5), max(t)+seconds(5)]);
            % legend('PM 2.5 [ug/m^3]', 'Location', 'northwest');
    nexttile(3, [2 1]);
        plot(tbl.t, tbl.lightVOC, 'Color', M(2,:), 'LineWidth', 1.5);
            grid on;
        title('Light VOC Signal (Fig 2602)');
            ylabel('Signal [ADU]');
                ylim([min(tbl.lightVOC)*0.99 max(tbl.lightVOC*1.01)]);
                xlim([min(t)-seconds(5), max(t)+seconds(5)]);
            % legend('Light VOC [ADU]', 'Location', 'northwest');
    nexttile(7, [2 1]);
        plot(tbl.t, tbl.heavyVOC, 'Color', M(1,:), 'LineWidth', 1.5);
            grid on;
        title('Heavy VOC Signal (Fig 2600)');
            ylabel('Signal [ADU]');
                ylim([min(tbl.heavyVOC)*0.99 max(tbl.heavyVOC*1.01)]);
                xlim([min(t)-seconds(5), max(t)+seconds(5)]);
            % legend('Heavy VOC [ADU]', 'Location', 'northwest');
    refreshdata;
end
%% REF: https://www.mathworks.com/help/matlab/ref/stackedplot.html
function alternateGraph(src)
    t = datetime(src.UserData(:, 1)) + hours(1);
    CO_2 = str2double(src.UserData(:,10));
    PM25 = str2double(src.UserData(:,12));
    lightVOC = str2double(src.UserData(:,7));
    heavyVOC = str2double(src.UserData(:,8));
    T = str2double(src.UserData(:,4));
    RH = str2double(src.UserData(:,5));
    CO2_tt = timetable(t, CO_2);
    PM25_tt = timetable(t, PM25);
    heavyVOC_tt = timetable(t, lightVOC);
    lightVOC_tt = timetable(t, heavyVOC);
    T_tt = timetable(t, T);
    RH_tt = timetable(t, RH);

    s = stackedplot(T_tt, RH_tt, CO2_tt, PM25_tt, heavyVOC_tt, lightVOC_tt);
    % s.LegendVisible = 'off';
    s.LineWidth = 1.5;
    s.LegendLabels = {'Temperature', 'Relative Humidity', 'Carbon Dioxide', 'PM 2.5', 'Light VOC', 'Heavy VOC'};
    grid on;
    refreshdata;
end
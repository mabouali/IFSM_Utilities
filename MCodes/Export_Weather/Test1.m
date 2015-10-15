clear;
clc;
close all

%% Station
Station.Name='KBS';
Station.Lat= 42.4;
Station.Lon=-85.3;
Station.CO2Level=390;
Station.NitrogenLevel=0.5;

%% Loading Data
Data=readtable('KBSData.csv');
Data=table2struct(Data,'ToScalar',true);

%% Exporting to IFSM WeatherFileFormat
tic;
export_IFSM_Weather('IFSM_Weather.wth', Data,Station);
toc;
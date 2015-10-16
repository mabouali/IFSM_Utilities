function [Options]=export_IFSM_Weather(filename, Data,Station,Options)
%% Checking Options content
if (nargin<4 || isempty(Options))
  Options.useOldFormat=false;
else
  if (~isfield(Options,'useOldFormat') || ...
      ~islogical(Options.useOldFormat) || ...
      isempty(Options.useOldFormat))
    Options.useOldFormat=false;
  end
end

%% getting default Options
if (nargin<1)
  return
end

%% Checking inputs
validateattributes(filename,{'char'},{'row'});

% checking the inputs are structure
if (~isstruct(Data) || ~isstruct(Station))
  error('Data and Station must be both structure.');
end

% making sure all the fields exists
switch Options.useOldFormat
  case false
    if any((~isfield(Data,{'Year','Month','Day','SRad','Tmean','Tmax','Tmin','TotalPr','MeanWindSpeed'})))
      error('When using new format, Data must contain all the following fields (case sensitive): Year, Month, Day, SRad, Tmean, Tmax, Tmin, TotalPr, MeanWindSpeed.')
    end
  case true
    if any((~isfield(Data,{'Year','Month','Day','SRad','Tmax','Tmin','TotalPr',})))
      error('When using old format, Data must contain all the following fields (case sensitive): Year, Month, Day, SRad, Tmax, Tmin, TotalPr.')
    end
end

if any((~isfield(Station,{'Name','Lat','Lon','CO2Level','NitrogenLevel'})))
  error('Station must contain all the following fields (case sensitive): Name, Lat, Lon, CO2Level, NitrogenLevel');
end

% checking the size of the fields
validateattributes(Data.Year,{'numeric'},{'vector'})
nData=numel(Data.Year);
validateattributes(Data.Month,{'numeric'},{'vector','numel',nData});
validateattributes(Data.Day,{'numeric'},{'vector','numel',nData});
validateattributes(Data.SRad,{'numeric'},{'vector','numel',nData});
validateattributes(Data.Tmax,{'numeric'},{'vector','numel',nData});
validateattributes(Data.Tmin,{'numeric'},{'vector','numel',nData});
validateattributes(Data.TotalPr,{'numeric'},{'vector','numel',nData});
if (~Options.useOldFormat)
  validateattributes(Data.Tmean,{'numeric'},{'vector','numel',nData});
  validateattributes(Data.MeanWindSpeed,{'numeric'},{'vector','numel',nData});
end

%% Preparing date column
% sorting data based on date if needed
dateNumber=datenum(Data.Year,Data.Month,Data.Day);
dDateNumber=diff(dateNumber);
if (any(dDateNumber<0))
  [dateNumber,idx]=sort(dateNumber);
  if (any(diff(dateNumber)==0))
    error('Repeated date in the data.')
  end
  Data.Year=Data.Year(idx);
  Data.Month=Data.Month(idx);
  Data.Day=Data.Day(idx);
  Data.SRad=Data.SRad(idx);
  Data.Tmax=Data.Tmax(idx);
  Data.Tmin=Data.Tmin(idx);
  Data.TotalPr=Data.TotalPr(idx);
  if (~Options.useOldFormat)
    Data.Tmean=Data.Tmean(idx);
    Data.MeanWindSpeed=Data.MeanWindSpeed(idx);
  end
else
  if (any(dDateNumber==0))
    error('Repeated date in the data.')
  end
end
% clear dDateNumber idx

% now ready to calculate the date based on IFSM Format, i.e. YYDDD
twoDigitYear=mod(Data.Year,100);
DayOfYear=dateNumber-datenum(Data.Year,1,1)+1;
% Removing last day of the leap years to make them 365 days
% IFSM only accepts 365 days in a year.
mask= (DayOfYear~=366);
twoDigitYear=twoDigitYear(mask);
DayOfYear=DayOfYear(mask);
Data.Year=Data.Year(mask);
Data.Month=Data.Month(mask);
Data.Day=Data.Day(mask);
Data.SRad=Data.SRad(mask);
Data.Tmax=Data.Tmax(mask);
Data.Tmin=Data.Tmin(mask);
Data.TotalPr=Data.TotalPr(mask);
if (~Options.useOldFormat)
  Data.Tmean=Data.Tmean(mask);
  Data.MeanWindSpeed=Data.MeanWindSpeed(mask);
end
YYDDD=twoDigitYear*1000+DayOfYear;

%% Making sure data is in row vector
if (~isrow(YYDDD))
  YYDDD=reshape(YYDDD,1,[]);
end
if (~isrow(Data.SRad))
  Data.SRad=reshape(Data.SRad,1,[]);
end
if (~isrow(Data.Tmax))
  Data.Tmax=reshape(Data.Tmax,1,[]);
end
if (~isrow(Data.Tmin))
  Data.Tmin=reshape(Data.Tmin,1,[]);
end
if (~isrow(Data.TotalPr))
  Data.TotalPr=reshape(Data.TotalPr,1,[]);
end
if (~Options.useOldFormat)
  if (~isrow(Data.Tmean))
    Data.Tmean=reshape(Data.Tmean,1,[]);
  end
  if (~isrow(Data.MeanWindSpeed))
    Data.MeanWindSpeed=reshape(Data.MeanWindSpeed,1,[]);
  end
end

%% Opening the output file
fid=fopen(filename,'w');
if (fid==-1)
  error('Cannot open the output file.')
end

%% writing the file
try
  % Writing the headers
  isSouthern= double(Station.Lat<0);
  fprintf(fid, ...
          '%-5s%6.1f%6.1f%6.1f%6.1f%6.1f\r\n', ...
          Station.Name, ...
          Station.Lat, ...
          Station.Lon, ...
          Station.CO2Level, ...
          isSouthern, ...
          Station.NitrogenLevel);
        
	% Writing the data
  if (Options.useOldFormat)
    fprintf(fid, ...
            '%5g%6.1f%6.1f%6.1f%6.1f\r\n', ...
            [YYDDD; Data.SRad; Data.Tmax; Data.Tmin; Data.TotalPr;]);
  else
    fprintf(fid, ...
            '%5g%6.1f%6.1f%6.1f%6.1f%6.1f%6.1f\r\n', ...
            [YYDDD; Data.SRad; Data.Tmean; Data.Tmax; Data.Tmin; Data.TotalPr; Data.MeanWindSpeed]);
  end
catch ME
  fclose(fid);
  rethrow(ME);
end

%% closing the file
fclose(fid);

end
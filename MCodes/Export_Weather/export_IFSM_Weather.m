function export_IFSM_Weather(filename, Data,Station)
%% Checking inputs
validateattributes(filename,{'char'},{'row'});

% checking the inputs are structure
if (~isstruct(Data) || ~isstruct(Station))
  error('Data and Station must be both structure.');
end

% making sure all the fields exists
if any((~isfield(Data,{'Year','Month','Day','SRad','Tmean','Tmax','Tmin','TotalPr','MeanWindSpeed'})))
  error('Data must contain all the following fields (case sensitive): Year, Month, Day, SRad, Tmean, Tmax, Tmin, TotalPr, MeanWindSpeed.')
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
validateattributes(Data.Tmean,{'numeric'},{'vector','numel',nData});
validateattributes(Data.Tmax,{'numeric'},{'vector','numel',nData});
validateattributes(Data.Tmin,{'numeric'},{'vector','numel',nData});
validateattributes(Data.TotalPr,{'numeric'},{'vector','numel',nData});
validateattributes(Data.MeanWindSpeed,{'numeric'},{'vector','numel',nData});

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
  Data.Tmean=Data.Tmean(idx);
  Data.Tmax=Data.Tmax(idx);
  Data.Tmin=Data.Tmin(idx);
  Data.TotalPr=Data.TotalPr(idx);
  Data.MeanWindSpeed=Data.MeanWindSpeed(idx);
else
  if (any(dDateNumber==0))
    error('Repeated date in the data.')
  end
end
% clear dDateNumber idx

% now ready to calculate the date based on IFSM Format, i.e. YYDDD
twoDigitYear=mod(Data.Year,100);
DayOfYear=dateNumber-datenum(Data.Year,1,1)+1;
YYDDD=twoDigitYear*1000+DayOfYear;

%% Making sure data is in row vector
if (~isrow(YYDDD))
  YYDDD=reshape(YYDDD,1,[]);
end
if (~isrow(Data.SRad))
  Data.SRad=reshape(Data.SRad,1,[]);
end
if (~isrow(Data.Tmean))
  Data.Tmean=reshape(Data.Tmean,1,[]);
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
if (~isrow(Data.MeanWindSpeed))
  Data.MeanWindSpeed=reshape(Data.MeanWindSpeed,1,[]);
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
  fprintf(fid, ...
          '%5g%6.1f%6.1f%6.1f%6.1f%6.1f%6.1f\r\n', ...
          [YYDDD; Data.SRad; Data.Tmean; Data.Tmax; Data.Tmin; Data.TotalPr; Data.MeanWindSpeed]);
        
catch ME
  fclose(fid);
  rethrow(ME);
end

%% closing the file
fclose(fid);

end
function [secondo,minuteo,houro]=timetran(second,minute,hour)
if nargin==1
    houro=floor(second/3600);
    minuteo=floor(mod(second,3600)/60);
    secondo=mod(second,60);
end
if nargin==3
    secondo=hour*3600+minute*60+second;
end
end
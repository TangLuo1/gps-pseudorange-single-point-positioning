%%
%gpsfileread
fid1=fopen('igs19962.sp3');
fid2=fopen('sdwa1000.18o');
fid3=fopen('BRDC1000.18p');
fid4=fopen('position_data2.txt','w');
line_num=0;
tc=0;
times=zeros(96,1);
sp3p=zeros(96,32,4);
flag1=0;
while(1)
    line_txt=fgetl(fid1);
    line_num=line_num+1;
    if line_txt==-1
        break;
    end
    if line_txt(1)=='*'
        tc=tc+1;
        %time only for 18.4.10
        times(tc)=str2double(line_txt(15:16))*3600+str2double(line_txt(18:19))*60+str2double(line_txt(21:31));
        for s=1:32
            line_txt=fgetl(fid1);
            line_num=line_num+1;
            if line_txt==-1
                disp(['error: igs19962.sp3 unexcepted file end, line',num2str(line_num)]);
                flag1=1;
                break;
            end
            sp3p(tc,s,:)=[str2double(line_txt(5:18))*1000
                str2double(line_txt(19:32))*1000
                str2double(line_txt(33:46))*1000
                str2double(line_txt(47:60))/10^6];
        end
        if flag1==1
            break;
        end
    end
end
fclose(fid1);
line_num=0;
tc=0;
s=1;
timeo=zeros(2878,1);
os=cell(2878,1);
ot=zeros(2878,33);
while(1)
    line_txt=fgetl(fid2);
    line_num=line_num+1;
    if line_txt==-1
        break;
    end
    if line_txt(1)=='>'
        tc=tc+1;
        s=1;
        %time only for 18.4.10
        timeo(tc)=str2double(line_txt(14:15))*3600+str2double(line_txt(17:18))*60+str2double(line_txt(20:29));
    end
    if line_txt(1)=='G'
        gpsnum=str2double(line_txt(2:3));
        if (32>=gpsnum)&&(gpsnum>=1)
            osa=[str2double(line_txt(6:17)),str2double(line_txt(22:33))];
            if(osa(1)~=0&&osa(2)~=0)
                %os(time,gps,[gps,wav1,wav2])
                ot(tc,33)=s;
                ot(tc,s)=gpsnum;
                os{tc}=[os{tc};osa];
                s=s+1;
            end
        end
    end
end
fclose(fid2);
fclose(fid3);

%%
%position
f1=1575420000;
f2=1227600000;
c=299792458;
%Nnow=find(timeo==timetran(0,35,0));
X=[-2687445.7003,4292269.7992,3864568.2131,0];
pca=[f1^2/(f1^2-f2^2),f2^2/(f1^2-f2^2)];
fprintf(fid4,'\t\t\t  %s\t\t\t\t\t\t  %s\t\t\t\t\t\t  %s\n','X','Y','Z');
for Nnow=1:2877
    pcb=pca.*os{Nnow};
    pc=pcb(:,1)-pcb(:,2);
    adt=zeros(ot(Nnow,33),1)+1;%adt=zeros(ot(Nnow,33),1)+c;
    P=eye(ot(Nnow,33));
    X(4)=0;
    nloop=0;
    while(nloop<10)
        if nloop==0
            tdel=pc/c;
        else
            tdel=sqrt(sum((X(1:3)-int(:,1:3)).^2,2))/c;
        end
        int=gpsinterp(timeo,times,sp3p,ot,Nnow,tdel);
        rho=sqrt(sum((int(:,1:3)-X(1:3)).^2,2));
        A=[(int(:,1:3)-X(1:3))./rho,adt];
        L=(pc-rho-X(4)+c*int(:,4));
        dX=(A'*P*A)\(A'*P*L);
        X=X-dX';
        nloop=nloop+1;
        if sqrt(sum(dX(1:3).^2))<0.000001
            break;
        end
    end
    [hour,minute,second]=timetran(timeo(Nnow));
%     disp([sprintf('18.04.10 %d:%d:%d',second,minute,hour) '   X=']);
%     disp(X);
    fprintf(fid4,'%2d:%2d:%2d\t  %19.12f\t  %19.12f\t  %19.12f\t\n',second,minute,hour,X(1),X(2),X(3));
    XX(Nnow,:)=X(1:3);
end
fclose(fid4);
plot3(XX(:,1),XX(:,2),XX(:,3),'.');
grid;
disp('00:35:00    X Y Z=');
disp(XX(timeo==timetran(0,35,0),:));
%winopen('position_data.txt')
%%
%interp
%int=cell(2878,1);
function [int]=gpsinterp(timeo,times,sp3p,ot,i,del)
%for i=1:length(timeo)
k=1;
int=zeros(ot(i,33),4);
while timeo(i)>times(k) && k<96
    k=k+1;
end
if k<=5
    for j=1:ot(i,33)
        int(j,:)=[
            interp_lar(times(1:10),sp3p(1:10,ot(i,j),1),timeo(i)-del(j)),...
            interp_lar(times(1:10),sp3p(1:10,ot(i,j),2),timeo(i)-del(j)),...
            interp_lar(times(1:10),sp3p(1:10,ot(i,j),3),timeo(i)-del(j)),...
            interp_lar(times(1:10),sp3p(1:10,ot(i,j),4),timeo(i)-del(j))];
    end
elseif k>=91
    for j=1:ot(i,33)
        int(j,:)=[
            interp_lar(times(96-9:96),sp3p(96-9:96,ot(i,j),1),timeo(i)-del(j)),...
            interp_lar(times(96-9:96),sp3p(96-9:96,ot(i,j),2),timeo(i)-del(j)),...
            interp_lar(times(96-9:96),sp3p(96-9:96,ot(i,j),3),timeo(i)-del(j)),...
            interp_lar(times(96-9:96),sp3p(96-9:96,ot(i,j),4),timeo(i)-del(j))];
    end
else
    for j=1:ot(i,33)
        int(j,:)=[
            interp_lar(times(k-4:k+5),sp3p(k-4:k+5,ot(i,j),1),timeo(i)-del(j)),...
            interp_lar(times(k-4:k+5),sp3p(k-4:k+5,ot(i,j),2),timeo(i)-del(j)),...
            interp_lar(times(k-4:k+5),sp3p(k-4:k+5,ot(i,j),3),timeo(i)-del(j)),...
            interp_lar(times(k-4:k+5),sp3p(k-4:k+5,ot(i,j),4),timeo(i)-del(j))];
    end
end
%end
end
%%
function [yy]=interp_lar(x,y,xx)
order=length(x);
if length(y)~=order
    yy=-Inf;
    return ;
end
x=reshape(x,1,order);
y=reshape(y,1,order);
m=xx-meshgrid(x);
m=m-diag(diag(m))+eye(order);
n=meshgrid(x(1:order))'-x(1:order)+eye(order);
yy=sum(prod(m,2)./prod(n,2).*y');
end
%%
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


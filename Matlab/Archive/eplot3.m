%*****************************************************************************************************
%NAME: eplot3.m																												
%AUTHOR: Ruello Rubino
%DATE: 2010-10-25
% Based on eplot.m by Andri M. Gretarsson																								
%																																	
%SYNTAX: eplot3(X,Y,Z, 'colour')																							
%																																	
%Note that 'colour' is NOT an optional argument.  																	
%																																	
%This function acts just like the built-in function 'plot3' but plots error-bars. The error-bars 	
%are plotted in the colour given by 'colour'.  'X', 'Y' and 'Z' are Nx2 matrixes, the first column 		
%representing the values of the coordinate (x, y or z), the second column representing the uncertainty	
%('error') of those values.  'colour' is a one-letter string which must be one of the letters allowed 
%in the built-in matlab function 'plot', to specify the plot colour.  Note that the function exits	
%with "hold" set to "off".  																								
%																																	
%This function does not print points in addition to the error bars.  Where the error bars cross, is 	
%the coordinate point.  This means that if both error bars are exceedingly small complared to the 	
%coordinate values, the mark will be correspondingly small.  In such situations, it may be better to	
%use 'plot3' directly and specify that the error is smaller than the size of the mark.					
%																																	
%EXAMPLE:
%
% X=[1.0	0.2																									
%   2.0	0.25]																																																							
% Y=[1.0 0.2																									
%   2.0	0.25]																																																									
% Z=[1.0	0.25																									
%   2.0	0.5]																																																									
% eplot3(X,Y,Z,'g')																									
%																																	
%plots a green cross of width 0.2 (in both x and y) and height 0.25 (in z) at coordinate (1.0,1.0,1.0), and a cross of width 0.25 	
%and height 0.5 at coordinate (2.0,2.0).  																			
%																																	
%LAST MODIFIED:  2010-10-25																									
%*****************************************************************************************************

function eplot3(x,y,z,colourstring)


xvalue=x(:,1);												%For clarity
xerror=x(:,2);
yvalue=y(:,1);
yerror=y(:,2);
zvalue=z(:,1);
zerror=z(:,2);

% % % plot(xvalue-xerror,yvalue-yerror,'w-',xvalue+xerror,yvalue+yerror,'w-'); hold on;	
% % % %Sets appropriate axes but otherwise invisible on a white background
hold on;
for i=1:length(xvalue)
   plot3([xvalue(i)-xerror(i) xvalue(i)+xerror(i)], [yvalue(i) yvalue(i)], [zvalue(i) zvalue(i)], colourstring);
   plot3([xvalue(i) xvalue(i)], [yvalue(i)-yerror(i) yvalue(i)+yerror(i)], [zvalue(i) zvalue(i)], colourstring);
   plot3([xvalue(i) xvalue(i)], [yvalue(i) yvalue(i)], [zvalue(i)-zerror(i) zvalue(i)+zerror(i)], colourstring);
end
hold off;


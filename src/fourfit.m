function p = fourfit(x,y,T,nharm)
% Fourier series fit with period T
% x,y: training data
% nharm= #harmonics
% p: estimated parameters
% See also: fourval

x=x(:);
X=ones(size(x));

for i=1:nharm
    
    X=[X sin(i*2*pi*x/T) cos(i*2*pi*x/T)];
    
end

p=X\y;

end


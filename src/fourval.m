function yhat = fourval(p,T,x)
% evaluates Fourier series with coefficients p
% T: period
% x: independent variables where prediction is to be computed
% See also: fourfit


p=p(:);
nharm=(length(p)-1)/2;

x=x(:);
X=ones(size(x));

for i=1:nharm
    
    X=[X sin(i*2*pi*x/T) cos(i*2*pi*x/T)];
    
end
yhat=X*p;

end


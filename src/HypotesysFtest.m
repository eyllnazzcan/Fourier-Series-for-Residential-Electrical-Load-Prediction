function fstat=HypotesysFtest(y,yhat,n,p)
    RSS=sum((y-yhat).^2);
    TSS=sum((y-mean(y)).^2);
    fstat=((TSS-RSS)/p)/(RSS/(n-p-1));
end
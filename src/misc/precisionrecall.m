function [rec,prec,ap,sortind]=precisionrecall(conf,labels,nfalseneg)
    if nargin<3 nfalseneg=0; end
    
    [so,sortind]=sort(-conf);
    tp=labels(sortind)==1;
    fp=labels(sortind)~=1;
    npos=length(find(labels==1))+nfalseneg;

    % compute precision/recall
    fp=cumsum(fp);
    tp=cumsum(tp);
    rec=tp/(npos+eps);
    prec=tp./(fp+tp);

    % compute average precision
    ap=0;
    for t=0:0.1:1
       p=max(prec(rec>=t));
       if isempty(p)
           p=0;
       end
       ap=ap+p/11;
    end
end
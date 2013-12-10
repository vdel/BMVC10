% function chi = chi2(h,g)
% 
% Compute Chi2 statistics between two L1 normalized vectors, h and g.
function chi = chi2(h,g)
    chi = 2 * sum(((h-g).^2) ./ (h+g+eps) );
return;

%Amplitud del EOG durante el seguimiento del péndulo
%p2p = percentil 95 - percentil 5%
function [p2p, rmsAmp] = amplitud_pendulo(x, valido);
x = x(valido(:));
p2p = NaN; rmsAmp = NaN;
if numel(x) < 3, return; end
s = sort(x); n = numel(s);
p2p = s(min(n, round(0.95*n))) - s(max(1, round(0.05*n)));
rmsAmp = sqrt(mean((x-mean(x)).^2));
end
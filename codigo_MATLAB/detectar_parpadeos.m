function [t_s, amp] = detectar_parpadeos(xt, valido, med, umbral, fs, cfg)
%xt: EOG vertical filtrado y con polaridad aplicada - med/umbral
%Los tramos invalidos se rellenan con la mediana, asi no pueden generar picos
s = xt(:);  s(~valido(:)) = med;
t_s = zeros(0,1);  amp = zeros(0,1);
if numel(s) < 3, return; end
[pk, loc] = findpeaks(s, 'MinPeakHeight', umbral, ...
    'MinPeakDistance', max(1, round(cfg.papadeo.distMin_s * fs)));
t_s = (loc(:) - 1) / fs;      %segundos desde el inicio del segmento
amp = pk(:) - med;
end

function [valido, codigo] = mascara_calidad(xRaw, xFilt, nf, sat, fs, cfg, tipoCanal, exclArchivo)
%Evalúa bloques de cfg.cal.bloque_s. tipoCanal: 'EEG' | 'EOGV' | 'EOGH'.
%Código (por muestra): 0 ok, 1 no finito, 2 saturación, 3 plano, 4 amplitud (solo EEG), 5 exclusión manual
n  = numel(xRaw);
nb = max(1, round(cfg.cal.bloque_s * fs));
codigo = zeros(n, 1, 'uint8');
esEEG = strcmp(tipoCanal, 'EEG');
if esEEG, flatMin = cfg.cal.flatStd_uV.EEG; else, flatMin = cfg.cal.flatStd_uV.EOG; end

for ini = 1:nb:n
    idx = ini:min(ini + nb - 1, n);
    c = 0;
    if any(nf(idx)),                         c = 1;
    elseif any(sat(idx)),                    c = 2;
    elseif std(xRaw(idx)) < flatMin,         c = 3;
    elseif esEEG && (max(xFilt(idx)) - min(xFilt(idx))) > cfg.cal.ptpMaxEEG_uV, c = 4;
    end
    codigo(idx) = c;
end

t = lower(tipoCanal);
for k = 1:height(exclArchivo)
    canal = exclArchivo.Canal{k};
    aplica = strcmp(canal, 'todos') || strcmp(canal, t) || (strcmp(canal, 'eog') && startsWith(t, 'eog'));
    if aplica
        i0 = max(1, floor(exclArchivo.Inicio_s(k) * fs) + 1);
        i1 = min(n, ceil(exclArchivo.Fin_s(k) * fs));
        if i1 >= i0, codigo(i0:i1) = 5; end
    end
end
valido = (codigo == 0);
end

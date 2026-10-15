function P = preprocesar_senales(data, fs, cfg)
%Marca muestras no finitas/saturadas (en la frecuencia original) y filtra
%Data: [muestras x canales] en microV.
q = max(1, round(fs / cfg.fsObjetivo));
fsN = fs / q;
[n, nC] = size(data);
nOut = ceil(n / q);
nSat = max(2, round(cfg.cal.satMin_ms * fs / 1000));

raw = zeros(nOut, nC);
nf  = false(nOut, nC);
sat = false(nOut, nC);
for c = 1:nC
    x = data(:, c);
    malo = ~isfinite(x);
    if any(malo)
        nf(unique(ceil(find(malo) / q)), c) = true;
        x = fillmissing(x, 'linear', 'EndValues', 'nearest');
    end
    sat(:, c) = saturacion_diezmada(x, q, nSat, nOut);
    if q > 1, raw(:, c) = decimate(x, q); else, raw(:, c) = x; end
end

fEEG   = filtro_pasabanda(cfg.eeg.bandpass,   fsN);
fBlink = filtro_pasabanda(cfg.eog.bpParpadeo, fsN);
fPend  = filtro_pasabanda(cfg.eog.bpPendulo,  fsN);

eeg = filtfilt(fEEG, raw(:, cfg.idxEEG));
P.coefOcular = [NaN NaN];
if cfg.eeg.corregirOcular
    eogEnBandaEEG = [filtfilt(fEEG, raw(:, cfg.idxEOG_V)), filtfilt(fEEG, raw(:, cfg.idxEOG_H))];
    ok = ~any(nf | sat, 2) & abs(eeg) < cfg.cal.ptpMaxEEG_uV;   % evita que artefactos grandes sesguen la regresión
    B = eogEnBandaEEG(ok, :) \ eeg(ok);
    eeg = eeg - eogEnBandaEEG * B;
    P.coefOcular = B(:)';
end

P.fs = fsN;  P.n = nOut;  P.q = q;
P.nf = nf;   P.sat = sat;
P.rawEEG  = raw(:, cfg.idxEEG);
P.rawEOGv = raw(:, cfg.idxEOG_V);
P.rawEOGh = raw(:, cfg.idxEOG_H);
P.eeg      = eeg;
P.eogBlink = filtfilt(fBlink, raw(:, cfg.idxEOG_V));
P.eogPendH = filtfilt(fPend,  raw(:, cfg.idxEOG_H));
P.eogPendV = filtfilt(fPend,  raw(:, cfg.idxEOG_V));
end

function d = filtro_pasabanda(banda, fs)
%IIR en secciones de segundo orden (estable con bandas angostas), se aplica con filtfilt (fase cero)
d = designfilt('bandpassiir', 'FilterOrder', 8, ...
    'HalfPowerFrequency1', banda(1), 'HalfPowerFrequency2', banda(2), 'SampleRate', fs);
end

function s = saturacion_diezmada(x, q, nMin, nOut)
%Saturación = racha de >= nMin muestras en el máximo o mínimo global del registro
s = false(nOut, 1);
if max(x) <= min(x), return; end
ext = (x >= max(x)) | (x <= min(x));
d = diff([0; ext(:); 0]);
ini = find(d == 1);  fin = find(d == -1) - 1;
largo = (fin - ini + 1) >= nMin;
for k = find(largo(:))'
    s(unique(ceil((ini(k):fin(k)) / q))) = true;
end
end

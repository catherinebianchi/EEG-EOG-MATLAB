function W = ventanas_eeg(x, valido, fs, cfg)
% Potencia por ventanas de igual duracion y solape 

nV   = round(cfg.eeg.durVentana_s * fs);
paso = max(1, round(nV * (1 - cfg.eeg.solape)));
nfft = max(256, 2^nextpow2(nV));
win  = hamming(nV);
ini  = (1:paso:(numel(x) - nV + 1))';
nW   = numel(ini);
W.inicioIdx = ini;
W.valida    = false(nW, 1);
W.thetaAbs = nan(nW,1); W.alphaAbs = nan(nW,1); W.betaAbs = nan(nW,1); W.totalAbs = nan(nW,1);
for k = 1:nW
    idx = ini(k):(ini(k) + nV - 1);
    if ~all(valido(idx)), continue; end         % no se mezclan tramos invalidos
    seg = x(idx);  seg = seg(:) - mean(seg);
    [Pxx, f] = pwelch(seg, win, 0, nfft, fs);
    tot = bandpower(Pxx, f, cfg.eeg.bandaTotal, 'psd');
    if ~(tot > 0), continue; end
    W.totalAbs(k) = tot;
    W.thetaAbs(k) = bandpower(Pxx, f, cfg.eeg.theta, 'psd');
    W.alphaAbs(k) = bandpower(Pxx, f, cfg.eeg.alpha, 'psd');
    W.betaAbs(k)  = bandpower(Pxx, f, cfg.eeg.beta,  'psd');
    W.valida(k) = true;
end
end

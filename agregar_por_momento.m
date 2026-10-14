function D = agregar_por_momento(Fseg, V, cfg)
% Une los segmentos de cada participante dentro de un mismo momento y prueba
% Se obtiene 1 fila por participante x momento x prueba 
% Mediciones repetidas no se duplican

clave = string(Fseg.ID) + "|" + string(Fseg.Archivo) + "|" + string(Fseg.Momento) + "|" + string(Fseg.Fase);
[G, k] = findgroups(clave);
n = max(G);
[~, primero] = unique(G, 'first');
parts = split(k, "|");  if size(parts, 2) ~= 4, parts = reshape(parts, [], 4); end
D = table(parts(:,1), parts(:,2), parts(:,3), parts(:,4), 'VariableNames', {'ID','Archivo','Momento','Fase'});
D.Iluminacion = string(Fseg.Iluminacion(primero));
D.Grupo       = string(Fseg.Grupo(primero));
D.Orden       = Fseg.Orden(primero);
D.N_segmentos = accumarray(G, 1, [n 1]);
D.Duracion_observada_s = accumarray(G, Fseg.Duracion_observada_s, [n 1], @sum, 0);

%EEG: promedio de TODAS las ventanas validas de ese momento
vk = string(V.ID) + "|" + string(V.Archivo) + "|" + string(V.Momento) + "|" + string(V.Fase);
[~, loc] = ismember(vk, k);
[~, ibw] = max([V.ThetaRel V.AlphaRel V.BetaRel], [], 2);
nb = ["theta","alpha","beta"];
campos = {'ThetaAbs','AlphaAbs','BetaAbs','ThetaRel','AlphaRel','BetaRel'};
for c = 1:numel(campos), D.(campos{c}) = nan(n, 1); end
D.N_ventanas = zeros(n, 1);  D.BandaPredominante = strings(n, 1);
D.PctVent_theta = nan(n,1);  D.PctVent_alpha = nan(n,1);  D.PctVent_beta = nan(n,1);
for g = 1:n
    w = (loc == g);
    D.N_ventanas(g) = sum(w);
    if ~any(w), continue; end
    for c = 1:numel(campos), D.(campos{c})(g) = mean(V.(campos{c})(w)); end
    [~, ib] = max([D.ThetaRel(g) D.AlphaRel(g) D.BetaRel(g)]);
    D.BandaPredominante(g) = nb(ib);
    D.PctVent_theta(g) = 100 * mean(ibw(w) == 1);
    D.PctVent_alpha(g) = 100 * mean(ibw(w) == 2);
    D.PctVent_beta(g)  = 100 * mean(ibw(w) == 3);
end
D.Valido_EEG = double(D.N_ventanas >= cfg.cal.minVentanasMomento);
for c = 1:numel(campos), D.(campos{c})(D.Valido_EEG == 0) = NaN; end

%Parpadeos: total de parpadeos / total de tiempo valido de EOG
ok = Fseg.Valido_EOG == 1;
D.N_parpadeos = zeros(n, 1);  D.Dur_valida_EOG_s = zeros(n, 1);
if any(ok)
    D.N_parpadeos      = accumarray(G(ok), Fseg.N_parpadeos(ok), [n 1], @sum, 0);
    D.Dur_valida_EOG_s = accumarray(G(ok), Fseg.Duracion_valida_EOG_s(ok), [n 1], @sum, 0);
end
D.Valido_EOG = double(D.Dur_valida_EOG_s >= cfg.cal.minDuracionParpadeo_s);
D.Parpadeos_min = nan(n, 1);
D.Parpadeos_min(D.Valido_EOG == 1) = 60 * D.N_parpadeos(D.Valido_EOG == 1) ./ D.Dur_valida_EOG_s(D.Valido_EOG == 1);

%Péndulo: promedio de la amplitud de los segmentos validos
for nombre = ["PendH_p2p_uV","PendH_rms_uV","PendV_p2p_uV","PendV_rms_uV"]
    v = Fseg.(nombre);  b = ~isnan(v);
    D.(nombre) = nan(n, 1);
    if any(b), D.(nombre) = accumarray(G(b), v(b), [n 1], @mean, NaN); end
end
D.Valido_Pendulo = double(~isnan(D.(['Pend' cfg.pendulo.canal '_p2p_uV'])));
end

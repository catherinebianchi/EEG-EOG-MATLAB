%% Procesar señales - filtardo, control de calidad y metricas por segmento

run('configuracion.m');
mapa = leer_mapa(cfg);
excl = leer_exclusiones(cfg);
archivos = unique(mapa.Archivo, 'stable');

filasCal={}; filasFase={}; filasVent={}; filasEv={};
nEjEOG= 0; nEjEEG = 0;
canalesQC = {'EEG', 'EOGV','EOGH'};
nombresBanda = {'theta','alpha','beta'};

for a = 1:numel(archivos)
    nombre = archivos{a};
    ruta = fullfile(cfg.carpetaDatos, nombre);
    if ~isfile(ruta), warning('No existe %s; se omite.', ruta); continue; end
    fprintf('[%d/%d] %s\n', a, numel(archivos), nombre);

    [data, fs] = cargar_biopac(ruta);
    P = preprocesar_senales(data, fs, cfg);
    clear data
    fsN= P.fs;
    exclA = excl(strcmp(excl.Archivo, nombre), :);

    [vEEG, cEEG] = mascara_calidad(P.rawEEG,  P.eeg,      P.nf(:,cfg.idxEEG),   P.sat(:,cfg.idxEEG),   fsN, cfg, 'EEG',  exclA);
    [vV,   cV  ] = mascara_calidad(P.rawEOGv, P.eogBlink, P.nf(:,cfg.idxEOG_V), P.sat(:,cfg.idxEOG_V), fsN, cfg, 'EOGV', exclA);
    [vH,   cH  ] = mascara_calidad(P.rawEOGh, P.eogPendH, P.nf(:,cfg.idxEOG_H), P.sat(:,cfg.idxEOG_H), fsN, cfg, 'EOGH', exclA);
    cods = {cEEG, cV, cH};

    %Umbral de parpadeo - 1 vez por archivo
    switch cfg.parpadeo.polaridad
        case 1, xt = P.eogBlink;
        case -1, xt = -P.eogBlink;
        otherwise, xt = abs(P.eogBlink);
    end

    if sum(vV)>60 * fsN
        med = median(xt(vV));
        umbral = med + cfg.parpadeo.kMAD * 1.4826 * median(abs(xt(vV)-med));
    else
        med = NaN; umbral = NaN;
        warning('%s: menos de 60 s validos de EOG vertical; no se estimaran parpadeos.', nombre);
    end

        filas = mapa(strcmp(mapa.Archivo, nombre), :);
    for r = 1:height(filas)
        fila = filas(r, :);
        id = fila.ID{1};  ilu = fila.Iluminacion{1};  fase = fila.Fase{1};  grupo = fila.Grupo{1};  mom = fila.Momento{1};
        i0 = max(1, round(fila.Inicio_s * fsN) + 1);
        i1 = min(P.n, round(fila.Fin_s * fsN));
        if i1 - i0 < 2
            warning('%s %s %s: segmento fuera del registro; se omite.', nombre, mom, fase); continue
        end
        idx = i0:i1;
        durObs = (i1 - i0 + 1) / fsN;

        %Matriz de calidad: una fila por ID, canal, iluminacion y fase
        pctVal = zeros(1, 3);
        for k = 1:3
            cod = cods{k}(idx);
            pctVal(k) = mean(cod == 0);
            filasCal{end+1, 1} = struct('ID', id, 'Archivo', nombre, 'Momento', mom, 'Iluminacion', ilu, 'Fase', fase, ...
                'Canal', canalesQC{k}, 'Inicio_s', fila.Inicio_s, 'Fin_s', fila.Fin_s, ...
                'Duracion_observada_s', durObs, 'Duracion_valida_s', sum(cod == 0) / fsN, ...
                'PctValido', 100 * pctVal(k), 'PctNoFinito', 100 * mean(cod == 1), ...
                'PctSaturacion', 100 * mean(cod == 2), 'PctPlano', 100 * mean(cod == 3), ...
                'PctAmplitud', 100 * mean(cod == 4), 'PctManual', 100 * mean(cod == 5), ...
                'Incluido', double(pctVal(k) >= cfg.cal.minValidoSegmento), ...
                'Fuente_limites', fila.Fuente_limites{1}); 
        end

        d = struct('ID', id, 'Archivo', nombre, 'Momento', mom, 'Iluminacion', ilu, 'Orden', fila.Orden, 'Fase', fase, 'Grupo', grupo, ...
            'Inicio_s', fila.Inicio_s, 'Fin_s', fila.Fin_s, ...
            'Duracion_observada_s', durObs, ...
            'Valido_EEG', 0, 'N_ventanas_validas', 0, 'N_ventanas_rechazadas', 0, ...
            'ThetaAbs', NaN, 'AlphaAbs', NaN, 'BetaAbs', NaN, ...
            'ThetaRel', NaN, 'AlphaRel', NaN, 'BetaRel', NaN, 'BandaPredominante', '', ...
            'Valido_EOG', 0, 'Duracion_valida_EOG_s', NaN, 'N_parpadeos', NaN, 'Parpadeos_min', NaN, ...
            'Amp_parpadeo_mediana_uV', NaN, ...
            'Valido_Pendulo', 0, 'PendH_p2p_uV', NaN, 'PendH_rms_uV', NaN, 'PendV_p2p_uV', NaN, 'PendV_rms_uV', NaN);

        if strcmp(fase, cfg.Pendulo)
            %EOG: amplitud del seguimiento del pendulo
            if pctVal(3) >= cfg.cal.minValidoSegmento && sum(vH(idx)) / fsN >= cfg.cal.minDuracionPendulo_s
                [d.PendH_p2p_uV, d.PendH_rms_uV] = amplitud_pendulo(P.eogPendH(idx), vH(idx));
            end
            if pctVal(2) >= cfg.cal.minValidoSegmento && sum(vV(idx)) / fsN >= cfg.cal.minDuracionPendulo_s
                [d.PendV_p2p_uV, d.PendV_rms_uV] = amplitud_pendulo(P.eogPendV(idx), vV(idx));
            end
            d.Valido_Pendulo = double(~isnan(d.(['Pend' cfg.pendulo.canal '_p2p_uV'])));
        else
            %EEG: potencia relativa por ventanas
            if ismember(fase, cfg.fasesEEG) && pctVal(1) >= cfg.cal.minValidoSegmento
                W = ventanas_eeg(P.eeg(idx), vEEG(idx), fsN, cfg);
                nOk = sum(W.valida);
                d.N_ventanas_validas = nOk;  d.N_ventanas_rechazadas = numel(W.valida) - nOk;
                if nOk >= cfg.cal.minVentanasEEG
                    ok = W.valida;
                    rel = [W.thetaAbs(ok), W.alphaAbs(ok), W.betaAbs(ok)] ./ W.totalAbs(ok);
                    d.Valido_EEG = 1;
                    d.ThetaAbs = mean(W.thetaAbs(ok));  d.AlphaAbs = mean(W.alphaAbs(ok));  d.BetaAbs = mean(W.betaAbs(ok));
                    d.ThetaRel = mean(rel(:,1));  d.AlphaRel = mean(rel(:,2));  d.BetaRel = mean(rel(:,3));
                    [~, ib] = max([d.ThetaRel d.AlphaRel d.BetaRel]);
                    d.BandaPredominante = nombresBanda{ib};
                    [~, ibw] = max(rel, [], 2);
                    for kk = find(ok)'
                        j = sum(ok(1:kk));
                        filasVent{end+1, 1} = struct('ID', id, 'Archivo', nombre, 'Momento', mom, 'Iluminacion', ilu, ...
                            'Fase', fase, 'Grupo', grupo, ...
                            'Inicio_ventana_s', (i0 + W.inicioIdx(kk) - 2) / fsN, ...
                            'ThetaAbs', W.thetaAbs(kk), 'AlphaAbs', W.alphaAbs(kk), 'BetaAbs', W.betaAbs(kk), ...
                            'ThetaRel', rel(j,1), 'AlphaRel', rel(j,2), 'BetaRel', rel(j,3), ...
                            'BandaPredominante', nombresBanda{ibw(j)}); 
                    end
                end
                if nEjEEG < 2           % figura de ejemplo: ventanas aceptadas (verde) y rechazadas (rojo)
                    nEjEEG = nEjEEG + 1;
                    fig = figure('Visible', 'off'); hold on
                    plot((idx - 1) / fsN, P.eeg(idx), 'k');
                    yl = cfg.cal.ptpMaxEEG_uV * [-1 1];
                    for kk = 1:numel(W.valida)
                        x0 = (i0 + W.inicioIdx(kk) - 2) / fsN;  x1 = x0 + cfg.eeg.durVentana_s;
                        if W.valida(kk), col = [0.2 0.7 0.2]; else, col = [0.9 0.2 0.2]; end
                        patch([x0 x1 x1 x0], [yl(1) yl(1) yl(2) yl(2)], col, 'FaceAlpha', 0.12, 'EdgeColor', 'none');
                    end
                    xlabel('Tiempo (s)'); ylabel('EEG filtrado (\muV)');
                    title(sprintf('%s | %s | %s: ventanas aceptadas (verde) / rechazadas (rojo)', id, mom, fase), 'Interpreter', 'none');
                    guardar_figura(fig, fullfile(cfg.dir.figuras, sprintf('ejemplo_ventanas_EEG_%s_%s_%s.png', id, mom, fase)));
                    close(fig);
                end
            end

            %EOG: parpadeos por minuto
            durV = sum(vV(idx)) / fsN;
            d.Duracion_valida_EOG_s = durV;
            if ismember(fase, cfg.fasesParpadeo) && ~isnan(umbral) && ...
                    pctVal(2) >= cfg.cal.minValidoSegmento && durV >= cfg.cal.minDuracionParpadeo_s
                [tB, aB] = detectar_parpadeos(xt(idx), vV(idx), med, umbral, fsN, cfg);
                d.Valido_EOG = 1;  d.N_parpadeos = numel(tB);
                d.Parpadeos_min = 60 * numel(tB) / durV;
                d.Amp_parpadeo_mediana_uV = median(aB);
                for kk = 1:numel(tB)
                    filasEv{end+1, 1} = struct('ID', id, 'Archivo', nombre, 'Momento', mom, 'Iluminacion', ilu, 'Fase', fase, ...
                        'Tiempo_s', (i0 - 1) / fsN + tB(kk), 'Amplitud_uV', aB(kk)); %#ok<SAGROW>
                end
                if nEjEOG < 3
                    nEjEOG = nEjEOG + 1;
                    fig = figure('Visible', 'off'); hold on
                    tt = (idx - 1) / fsN;
                    plot(tt, xt(idx), 'k');
                    plot([tt(1) tt(end)], [umbral umbral], 'r--');
                    plot((i0 - 1) / fsN + tB, med + aB, 'rv', 'MarkerFaceColor', 'r');
                    inval = ~vV(idx);
                    plot(tt(inval), xt(idx(inval)), '.', 'Color', [0.8 0.5 0]);
                    xlabel('Tiempo (s)'); ylabel('EOG vertical filtrado (\muV)');
                    title(sprintf('%s | %s | %s: %d parpadeos (triangulos); naranja = intervalo excluido', ...
                        id, mom, fase, numel(tB)), 'Interpreter', 'none');
                    guardar_figura(fig, fullfile(cfg.dir.figuras, sprintf('ejemplo_parpadeos_%s_%s_%s.png', id, mom, fase)));
                    close(fig);
                end
            end
        end
        filasFase{end+1, 1} = d;
    end
    fprintf('    coeficientes de correccion ocular EEG (V,H): %s\n', mat2str(P.coefOcular, 3));
end

a_tabla = @(c) struct2table(vertcat(c{:}));
writetable(a_tabla(filasCal),  fullfile(cfg.dir.calidad,    'matriz_calidad.csv'));
writetable(a_tabla(filasFase), fullfile(cfg.dir.procesados, 'datos_segmento.csv'));
writetable(mapa,               fullfile(cfg.dir.procesados, 'mapa_segmentos.csv'));
if ~isempty(filasVent), writetable(a_tabla(filasVent), fullfile(cfg.dir.procesados, 'ventanas_EEG.csv')); end
if ~isempty(filasEv),   writetable(a_tabla(filasEv),   fullfile(cfg.dir.procesados, 'eventos_EOG.csv'));  end
save(fullfile(cfg.dir.procesados, 'parametros_utilizados.mat'), 'cfg');
fprintf('\nProcesamiento terminado: %d segmentos, %d ventanas EEG validas, %d parpadeos.\n', ...
    numel(filasFase), numel(filasVent), numel(filasEv));


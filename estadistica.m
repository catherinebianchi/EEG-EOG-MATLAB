%% Estadística: una fila por participantes por momento
%Diseño del experimento: 
%antes -> durante_luz -> despues_luz -> 
%durante_oscuridad -> %despues_oscuridad

run('configuracion.m');
Fseg = readtable(fullfile(cfg.dir.procesados,'datos_segmento.csv'),'TextType','string');
Q = readtable(fullfile(cfg.dir.calidad,'matriz_calidad.csv'),'TextType','string');
V = readtable(fullfile(cfg.dir.procesados,'ventanas_EEG.csv'), 'TextType','string');

%Exclusiones 
Fseg = Fseg(~ismember(Fseg.Archivo, string(cfg.archivosExcluir)) & ~ismember(Fseg.ID, string(cfg.idsExcluir)), :);
V = V(~ismember(V.Archivo, string(cfg.archivosExcluir)) & ~ismember(V.ID, string(cfg.idsExcluir)), :);

%% 1. Base por participante x momento x prueba
D = agregar_por_momento(Fseg, V, cfg);
writetable(D, fullfile(cfg.dir.procesados, 'datos_fase.csv'));

%% 2. Calidad por archivo y canal
[G, arch, can] = findgroups(Q.Archivo, Q.Canal);
R = table(arch, can, 'VariableNames', {'Archivo','Canal'});
R.N_segmentos           = splitapply(@numel, Q.PctValido, G);
R.PctValido_medio       = splitapply(@mean,  Q.PctValido, G);
R.PctValido_min         = splitapply(@min,   Q.PctValido, G);
R.N_segmentos_excluidos = splitapply(@(p) sum(p < 100*cfg.cal.minValidoSegmento), Q.PctValido, G);
R.Revisar = R.PctValido_medio < cfg.cal.alertaPctValido | R.N_segmentos_excluidos > 0;
writetable(R, fullfile(cfg.dir.calidad, 'resumen_calidad_por_archivo.csv'));
writetable(R(R.Revisar, :), fullfile(cfg.dir.calidad, 'archivos_para_revision.csv'));
fprintf('Archivo-canal a revisar por calidad: %d de %d\n', sum(R.Revisar), height(R));

%% 3. Tabla de muestra
Tm = table();
Tm.n_planificado        = cfg.nPlanificado;
Tm.n_en_excel           = numel(unique(D.ID));
Tm.n_EEG_ojos_cerrados  = numel(unique(D.ID(D.Valido_EEG == 1 & D.Fase == "OjosCerrados")));
Tm.n_EEG_exposicion     = numel(unique(D.ID(D.Valido_EEG == 1 & D.Fase == "Exposicion")));
Tm.n_parpadeos_validos  = numel(unique(D.ID(D.Valido_EOG == 1)));
Tm.n_pendulo_validos    = numel(unique(D.ID(D.Valido_Pendulo == 1)));
writetable(Tm, fullfile(cfg.dir.tablas, 'tabla_muestra.csv'));  disp(Tm)

%% 4. EEG "durante" y "despues": theta/alfa/beta y banda predominante por archivo (4 datos por archivo + basal)
cols = {'ID','Archivo','Momento','Fase','N_ventanas','ThetaAbs','AlphaAbs','BetaAbs','ThetaRel','AlphaRel','BetaRel', ...
    'BandaPredominante','PctVent_theta','PctVent_alpha','PctVent_beta'};
E = D(D.Valido_EEG == 1 & ismember(D.Fase, ["OjosCerrados","Exposicion"]), cols);
writetable(E, fullfile(cfg.dir.tablas, 'EEG_bandas_por_archivo_y_momento.csv'));

%% 5. Descriptivos (promedios) de EEG y EOG
vars = {'ThetaRel','AlphaRel','BetaRel','Parpadeos_min','PendH_p2p_uV','PendV_p2p_uV'};
Dd = descriptivos(D, vars, {'Momento','Fase'});
writetable(Dd(Dd.N > 0, :), fullfile(cfg.dir.tablas, 'descriptivos_por_momento.csv'));

%% 6. Comparaciones pareadas (Wilcoxon) entre momentos de la misma prueba
colPend = ['Pend' cfg.pendulo.canal '_p2p_uV'];
modelos = {
    'AlphaRel',    'Valido_EEG',     'OjosCerrados', cfg.momentosDespues;
    'ThetaRel',    'Valido_EEG',     'OjosCerrados', cfg.momentosDespues;
    'BetaRel',     'Valido_EEG',     'OjosCerrados', cfg.momentosDespues;
    colPend,       'Valido_Pendulo', 'Pendulo',      cfg.momentosDespues;
    'AlphaRel',    'Valido_EEG',     'Exposicion',   cfg.momentosDurante;
    'ThetaRel',    'Valido_EEG',     'Exposicion',   cfg.momentosDurante;
    'BetaRel',     'Valido_EEG',     'Exposicion',   cfg.momentosDurante;
    'Parpadeos_min','Valido_EOG',    'Exposicion',   cfg.momentosDurante};
filasC = {};
for r = 1:size(modelos, 1)
    mom = modelos{r,4};
    for par = nchoosek(1:numel(mom), 2)'
        C = cambio_entre_momentos(D, modelos{r,1}, modelos{r,2}, modelos{r,3}, mom{par(1)}, mom{par(2)});
        p = NaN;  if height(C) >= 5, p = signrank(C.Delta); end
        nota = "";  if any(strcmp(mom{par(1)}, {'despues_luz','durante_luz'})), nota = "exploratorio (orden fijo luz->oscuridad)"; end
        q = prctile(C.Delta, [25 75]);  if isempty(C.Delta), q = [NaN NaN]; end
        filasC{end+1, 1} = struct('Variable', string(modelos{r,1}), 'Prueba', string(modelos{r,3}), ...
            'Contraste', string(mom{par(2)}) + " - " + string(mom{par(1)}), 'n_pares', height(C), ...
            'Mediana_cambio', median(C.Delta), 'Q1', q(1), 'Q3', q(2), 'p_Wilcoxon', p, ...
            'Nota', nota); 
        writetable(C, fullfile(cfg.dir.tablas, sprintf('cambio_%s_%s_%s_menos_%s.csv', ...
            modelos{r,1}, modelos{r,3}, mom{par(2)}, mom{par(1)})));
    end
end
TC = struct2table(vertcat(filasC{:}));
writetable(TC, fullfile(cfg.dir.resultados, 'comparaciones_pareadas.csv'));

%% 7. Asociacion EOG-EEG (un dato por persona): parpadeos durante la exposicion vs cambio de alfa despues - antes
filasA = {};
for ilu = ["luz","oscuridad"]
    B = D(D.Fase == "Exposicion" & D.Momento == "durante_" + ilu & D.Valido_EOG == 1, {'ID','Parpadeos_min'});
    Ca = cambio_entre_momentos(D, 'AlphaRel', 'Valido_EEG', 'OjosCerrados', 'antes', char("despues_" + ilu));
    [~, ib, ia] = intersect(string(B.ID), Ca.ID);
    rho = NaN;  p = NaN;
    if numel(ib) >= 5, [rho, p] = corr(B.Parpadeos_min(ib), Ca.Delta(ia), 'Type', 'Spearman', 'Rows', 'complete'); end
    filasA{end+1, 1} = struct('Iluminacion', ilu, 'n', numel(ib), 'rho_Spearman', rho, 'p', p);
end
writetable(struct2table(vertcat(filasA{:})), fullfile(cfg.dir.resultados, 'asociacion_parpadeos_cambio_alfa.csv'));

%% 8. Modelos mixtos y sensibilidad 
filasM = {};  filasAn = {};
for escenario = ["Principal","Sensibilidad"]
    Dm = D;
    if escenario == "Sensibilidad", Dm = D(~ismember(D.ID, string(cfg.idsSensibilidad)), :); end
    for r = 1:size(modelos, 1)
        [an, co, info] = ajustar_modelo(Dm, modelos{r,1}, modelos{r,2}, modelos{r,3}, modelos{r,4}, cfg);
        fprintf('Modelo %-14s %-12s %-12s n_obs=%d n_ID=%d %s\n', modelos{r,1}, modelos{r,3}, escenario, info.n_obs, info.n_ID, info.error);
        if ~isempty(co)
            co.Escenario = repmat(escenario, height(co), 1);  co.Variable = repmat(string(modelos{r,1}), height(co), 1);
            co.Prueba = repmat(string(modelos{r,3}), height(co), 1);
            co.n_obs = repmat(info.n_obs, height(co), 1);  co.n_ID = repmat(info.n_ID, height(co), 1);
            filasM{end+1, 1} = co; 
        end
        if ~isempty(an)
            an.Escenario = repmat(escenario, height(an), 1);  an.Variable = repmat(string(modelos{r,1}), height(an), 1);
            an.Prueba = repmat(string(modelos{r,3}), height(an), 1);
            filasAn{end+1, 1} = an; 
        end
    end
end
if ~isempty(filasM),  writetable(vertcat(filasM{:}),  fullfile(cfg.dir.resultados, 'modelos_coeficientes.csv')); end
if ~isempty(filasAn), writetable(vertcat(filasAn{:}), fullfile(cfg.dir.resultados, 'modelos_anova.csv'));  end
disp('Estadistica terminada. Tablas en tablas y resultados en resultados.');



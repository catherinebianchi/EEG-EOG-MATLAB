%% Inventario 

run('configuracion.m');
[mapa, descartadas] = leer_mapa(cfg);
if ~isempty(descartadas)
    writetable(descartadas, fullfile(cfg.dir.inventario, 'segmentos_descartados.csv'));
    fprintf('%d segmentos del Excel NO tienen tiempos y no se analizaran (ver segmentos_descartados.csv).\n', height(descartadas));
end

enDisco = dir(fullfile(cfg.carpetaDatos, '*.mat'));
nombresDisco = {enDisco.name};
nombresMapa = unique(mapa.Archivo, 'stable');
todos = unique([nombresMapa(:); nombresDisco(:)],'stable');

nA = numel(todos);
inv = table(todos, false(nA,1), false(nA,1), cell(nA,1), nan(nA,1), nan(nA,1), cell(nA,1), cell(nA,1), ...
    nan(nA,1), false(nA,1), false(nA,1), cell(nA,1), ...
    'VariableNames', {'Archivo','En_disco','En_mapa','ID_en_mapa','Fs_Hz','Duracion_s', ...
    'Canales','Unidades','N_segmentos','Tiene_Luz','Tiene_Oscuridad','Estado'});
for a = 1:nA
    nom = todos{a};
    inv.En_disco(a) = ismember(nom, nombresDisco);
    inv.En_mapa(a)  = ismember(nom, nombresMapa);
    filas = mapa(strcmp(mapa.Archivo, nom), :);
    inv.ID_en_mapa{a} = strjoin(unique(filas.ID)', ';');
    inv.N_segmentos(a) = height(filas);
    inv.Tiene_Luz(a) = any(strcmp(filas.Iluminacion, 'Luz'));
    inv.Tiene_Oscuridad(a) = any(strcmp(filas.Iluminacion, 'Oscuridad'));
    estado = {};
    if inv.En_disco(a)
        try
            m = matfile(fullfile(cfg.carpetaDatos, nom));
            sz = size(m, 'data');
            labs = cellstr(m.labels);  uns = cellstr(m.units);
            isiVal = m.isi; isiU = lower(strtrim(char(m.isi_units)));
            if strcmp(isiU, 'ms'), fsA = 1000/isiVal(1); else, fsA = 1/isiVal(1); end
            inv.Fs_Hz(a) = fsA;  inv.Duracion_s(a) = max(sz)/fsA;
            inv.Canales{a} = strjoin(strtrim(labs)', ' | ');
            inv.Unidades{a} = strjoin(strtrim(uns)', ' | ');
            if min(sz) ~= 3, estado{end+1} = sprintf('%d canales (se esperaban 3)', min(sz)); end
            if ~isempty(filas) && max(filas.Fin_s) > inv.Duracion_s(a) + 1
                estado{end+1} = 'segmentos exceden la duracion del registro';
            end
        catch ME
            estado{end+1} = ['error de lectura: ' ME.message];
        end
    else
        estado{end+1} = 'archivo del mapa NO encontrado en disco';
    end
    if ~inv.En_mapa(a), estado{end+1} = 'archivo en disco sin filas en el mapa'; end
    
    %ID debe aparecer en el nombre del archivo 
    ids = unique(filas.ID);
    for k = 1:numel(ids)
        if ~contains(lower(nom), lower(ids{k}))
            estado{end+1} = sprintf('ID %s no coincide con el nombre del archivo', ids{k}); %#ok<SAGROW>
        end
    end
    if isempty(estado), inv.Estado{a} = 'OK'; else, inv.Estado{a} = strjoin(estado, '; '); end
end

writetable(inv, fullfile(cfg.dir.inventario, 'inventario_participantes.csv'));
try writetable(inv, fullfile(cfg.dir.inventario, 'inventario_participantes.xlsx')); catch, end

idsMapa = unique(mapa.ID);
idsConArchivo = unique(mapa.ID(ismember(mapa.Archivo, nombresDisco)));
fprintf('\nn planificado = %d | n con filas en el mapa = %d | n con archivo en disco = %d\n', ...
    cfg.nPlanificado, numel(idsMapa), numel(idsConArchivo));
problemas = inv(~strcmp(inv.Estado, 'OK'), {'Archivo','Estado'});
if isempty(problemas), disp('Inventario sin problemas.'); else, disp(problemas); end

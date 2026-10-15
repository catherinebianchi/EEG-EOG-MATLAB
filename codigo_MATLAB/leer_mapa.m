function [mapa, descartadas] = leer_mapa(cfg)
%Lee el Excel y lo convierte al formato interno
%subject (o ID) | momento | fase (o prueba) | inicio_seg (o Inicio_s) | fin_seg (o Fin_s)

if ~isfile(cfg.archivoMapa), error('No existe el archivo de segmentos: %s', cfg.archivoMapa); end
[~, ~, ext] = fileparts(cfg.archivoMapa);
if any(strcmpi(ext, {'.xlsx','.xls','.xlsm'}))
    T = readtable(cfg.archivoMapa, 'Sheet', cfg.hojaMapa, 'VariableNamingRule', 'preserve');
else
    T = readtable(cfg.archivoMapa, 'VariableNamingRule', 'preserve');
end
nombres = T.Properties.VariableNames;
norm = cellfun(@normalizar_texto, nombres, 'UniformOutput', false);
buscar = @(alias) find(ismember(norm, cellfun(@normalizar_texto, alias, 'UniformOutput', false)), 1);

cID  = buscar({'ID','subject','sujeto','participante'});
cMom = buscar({'momento'});
cFas = buscar({'fase','prueba'});
cIni = buscar({'Inicio_s','inicio_seg'});
cFin = buscar({'Fin_s','fin_seg'});
cArc = buscar({'Archivo'});
cFue = buscar({'Fuente_limites'});
req = {cID,'subject/ID'; cMom,'momento'; cFas,'fase'; cIni,'inicio_seg'; cFin,'fin_seg'};
for k = 1:size(req,1)
    if isempty(req{k,1})
        error('Falta la columna "%s" en %s. Columnas encontradas: %s', req{k,2}, cfg.archivoMapa, strjoin(nombres, ', '));
    end
end

txt = @(x) strtrim(cellstr(string(x)));
n = height(T);
mapa = table();
mapa.ID = txt(T{:, cID});
if isempty(cArc)
    mapa.Archivo = cellfun(@(s) sprintf(cfg.patronArchivo, s), mapa.ID, 'UniformOutput', false);
else
    arch = txt(T{:, cArc});
    sinExt = ~endsWith(lower(arch), '.mat');  arch(sinExt) = strcat(arch(sinExt), '.mat');
    mapa.Archivo = arch;
end

momRaw = txt(T{:, cMom});  fasRaw = txt(T{:, cFas});
mapa.Momento = cell(n,1);  mapa.Iluminacion = cell(n,1);  mapa.Grupo = cell(n,1);
mapa.Fase = cell(n,1);     mapa.Orden = nan(n,1);
for i = 1:n
    t = normalizar_texto(momRaw{i});
    if contains(t, 'antes')
        mapa.Grupo{i} = 'Basal';  mapa.Iluminacion{i} = 'Basal';  mapa.Momento{i} = 'antes';  mapa.Orden(i) = 0;
    else
        if contains(t, 'durante'), mapa.Grupo{i} = 'Durante'; pre = 'durante';
        elseif contains(t, 'despues'), mapa.Grupo{i} = 'Despues'; pre = 'despues';
        else, error('Fila %d: momento "%s" no reconocido (antes, durante_luz, despues_luz, durante_oscuridad, despues_oscuridad).', i, momRaw{i});
        end
        if contains(t, 'oscur'), mapa.Iluminacion{i} = 'Oscuridad'; mapa.Orden(i) = 2; suf = 'oscuridad';
        elseif contains(t, 'luz'), mapa.Iluminacion{i} = 'Luz'; mapa.Orden(i) = 1; suf = 'luz';
        else, error('Fila %d: momento "%s" no indica luz ni oscuridad.', i, momRaw{i});
        end
        mapa.Momento{i} = [pre '_' suf];
    end
    mapa.Fase{i} = prueba_canonica(fasRaw{i}, cfg);
end
mapa.Inicio_s = tonum(T{:, cIni});
mapa.Fin_s    = tonum(T{:, cFin});
mapa.Duracion_observada_s = mapa.Fin_s - mapa.Inicio_s;
if isempty(cFue), mapa.Fuente_limites = repmat({''}, n, 1); else, mapa.Fuente_limites = txt(T{:, cFue}); end

malas = isnan(mapa.Inicio_s) | isnan(mapa.Fin_s) | mapa.Fin_s <= mapa.Inicio_s;
descartadas = mapa(malas, :);
if any(malas)
    warning('%d segmentos sin tiempos validos (vacios o fin <= inicio) se descartan; quedan listados en inventario/segmentos_descartados.csv.', sum(malas));
    mapa = mapa(~malas, :);
end
end

function fase = prueba_canonica(texto, cfg)
t = normalizar_texto(texto);
for k = 1:size(cfg.mapaPruebas, 1)
    if contains(t, cfg.mapaPruebas{k,1}), fase = cfg.mapaPruebas{k,2}; return; end
end
warning('Prueba "%s" no esta en cfg.mapaPruebas; se conserva tal cual.', texto);
fase = strtrim(texto);
end

function v = tonum(x)
if isnumeric(x), v = double(x); return; end
v = str2double(strrep(cellstr(string(x)), ',', '.'));
end

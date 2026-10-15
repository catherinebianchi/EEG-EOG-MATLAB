function excl = leer_exclusiones(cfg)
% Intervalos a excluir manualmente

excl = table(cell(0,1), cell(0,1), zeros(0,1), zeros(0,1), cell(0,1), ...
    'VariableNames', {'Archivo','Canal','Inicio_s','Fin_s','Razon'});
if ~isfile(cfg.archivoExcl), return; end
T = readtable(cfg.archivoExcl);
if isempty(T), return; end
req = {'Archivo','Canal','Inicio_s','Fin_s'};
miss = req(~ismember(req, T.Properties.VariableNames));
if ~isempty(miss), error('exclusiones_manuales: faltan columnas: %s', strjoin(miss, ', ')); end
arch = strtrim(cellstr(string(T.Archivo)));
sinExt = ~endsWith(lower(arch), '.mat'); arch(sinExt) = strcat(arch(sinExt), '.mat');
excl.Archivo  = arch;
excl.Canal    = cellfun(@normalizar_texto, cellstr(string(T.Canal)), 'UniformOutput', false);
excl.Canal(strcmp(excl.Canal, 'todas')) = {'todos'};
excl.Inicio_s = double(T.Inicio_s);
excl.Fin_s    = double(T.Fin_s);
if ismember('Razon', T.Properties.VariableNames), excl.Razon = cellstr(string(T.Razon));
else, excl.Razon = repmat({''}, height(T), 1); end
end

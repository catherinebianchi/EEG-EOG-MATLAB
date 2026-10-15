function [data, fs, labels, units] = cargar_biopac(ruta)
% Lee un .mat y devuelve data [muestras x canales] en microV
S = load(ruta);
req = {'data','labels','units','isi','isi_units'};
faltan = req(~isfield(S, req));
if ~isempty(faltan)
    error('%s no tiene los campos esperados de Biopac. Faltan: %s', ruta, strjoin(faltan, ', '));
end
data   = double(S.data);
if size(data,1) < size(data,2), data = data'; end
labels = strtrim(cellstr(S.labels));
units  = strtrim(cellstr(S.units));

isiVal = double(S.isi(1));
isiU   = lower(strtrim(char(S.isi_units)));
switch isiU
    case 'ms', fs = 1000 / isiVal;
    case 's',  fs = 1 / isiVal;
    case {'us','micro s'}, fs = 1e6 / isiVal;
    otherwise, error('Unidad de isi no reconocida: %s', isiU);
end

for c = 1:numel(units) %En microvoltios
    u = lower(strrep(units{c}, ' ', ''));
    if any(strcmp(u, {'mv'})), data(:,c) = data(:,c) * 1e3;
    elseif strcmp(u, 'v'), data(:,c) = data(:,c) * 1e6;
    elseif any(strcmp(u, {'microv','uv'})) || contains(u, 'v') && numel(u) <= 3
 
    else
        warning('Unidad "%s" del canal %d no reconocida; se deja sin convertir.', units{c}, c);
    end
end
end

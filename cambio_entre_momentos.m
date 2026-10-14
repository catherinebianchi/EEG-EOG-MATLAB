function C = cambio_entre_momentos(D, var, flagValido, prueba, mom0, mom1)
%Cambio (momento1-momento0= de 'var' por participante usando filas válidas

sub = D(D.(flagValido) == 1 & ~isnan(D.(var)) & string(D.Fase) == string(prueba) & ...
    ismember(string(D.Momento), [string(mom0) string(mom1)]), :);
C = table(strings(0,1), zeros(0,1), zeros(0,1), zeros(0,1), 'VariableNames',{'ID', 'Inicial', 'Final', 'Delta'});
ids = unique(string(sub.ID));
for k = 1:numel(ids)
    mk = string(sub.ID) == ids(k);
    a = sub.(var)(mk & string(sub.Momento) == string(mom0));
    b = sub.(var)(mk & string(sub.Momento) == string(mom1));
    if isscalar(a) && isscalar(b), C(end+1, :) = {ids(k), a, b, b-a};
    end
end
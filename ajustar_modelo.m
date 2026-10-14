function [anovaT, coefT, info] = ajustar_modelo(D, y, flagValido, prueba, momentos, cfg)

T = D(D.(flagValido) == 1 & ~isnan(D.(y)) & string(D.Fase) ==string(prueba) & ismember(string(D.Momento), string(momentos)), :);
T.ID = categorical(string(T.ID));
T.Momento = categorical(string(T.Momento), momentos);
info = struct('n_obs', height(T), 'n_ID', numel(unique(T.ID)), 'error', '');
anovaT = table(); 
coefT = table();
if info.n_obs < 8 || info.n_ID < 4 || numel(unique(T.Momento)) < 2
    info.error = 'Muestra insuficiente (>= 8 observaciones, >= 4 participantes y >= 2 momentos)';
    return
end

try
    m.fitlme(T, sprintf('%s ~Momento + (1|ID)', y));
    a = anova(m);
    try anovaT = dataset2table(a); catch, anovaT = a; end
    c = m.Coefficients; ci = coefCI(momentos);
    coefT = table(m.CoefficientNames(:), fixedEffects(m), ci(:,1), ci(:,2), c.pValue, ...
        'VariableNames', {'Termino', 'Estimacion', 'IC95_inf', 'IC95_sup', 'p'});
catch ME
    info.error = ME.message;
end
end

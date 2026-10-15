function grafica_pareada(ax, D, var, flagValido, prueba, momentos, etiquetas, ylab)
% Una linea gris por participante (mediciones repetidas) y la mediana en negro

sub = D(D.(flagValido) == 1 & isfinite(D.(var)) & string(D.Fase) == string(prueba) & ...
    ismember(string(D.Momento), string(momentos)), :);
ids = unique(string(sub.ID));
M = nan(numel(ids), numel(momentos));
for j = 1:numel(momentos)
    s = sub(string(sub.Momento) == string(momentos{j}), :);
    [~, loc] = ismember(string(s.ID), ids);
    M(loc, j) = s.(var);
end
hold(ax, 'on');
for i = 1:numel(ids), plot(ax, 1:numel(momentos), M(i, :), '-o', 'Color', [0.65 0.65 0.65]); end
plot(ax, 1:numel(momentos), median(M, 1, 'omitnan'), '-s', 'Color', 'k', 'LineWidth', 2, 'MarkerFaceColor', 'k');
set(ax, 'XTick', 1:numel(momentos), 'XTickLabel', etiquetas); xlim(ax, [0.7 numel(momentos) + 0.3]);
ylabel(ax, ylab);
title(ax, sprintf('n = %d participantes (%d completos)', numel(ids), sum(all(~isnan(M), 2))));
end

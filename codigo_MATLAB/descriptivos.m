function D = descriptivos(T, vars, gvars)

gcols = cell(1, numel(gvars));
for k = 1:numel(gvars), gcols{k} = string(T.(gvars{k})); end
keys = cell(1, numel(gvars));
[G, keys{:}] = findgroups(gcols{:});
filas = {};
for g = 1:max(G)
    for v = 1:numel(vars)
        x = T.(vars{v})(G == g);  x = x(~isnan(x));
        s = struct();
        for k = 1:numel(gvars), s.(gvars{k}) = keys{k}(g); end
        s.Variable = string(vars{v});
        s.N = numel(x);
        if isempty(x)
            s.Media = NaN; s.DE = NaN; s.Mediana = NaN; s.Q1 = NaN; s.Q3 = NaN; s.Min = NaN; s.Max = NaN;
        else
            q = prctile(x, [25 75]);
            s.Media = mean(x); s.DE = std(x); s.Mediana = median(x);
            s.Q1 = q(1); s.Q3 = q(2); s.Min = min(x); s.Max = max(x);
        end
        filas{end+1, 1} = s; 
    end
end
D = struct2table(vertcat(filas{:}));
end

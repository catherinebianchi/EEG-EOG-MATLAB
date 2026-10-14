function t = normalizar_texto(txt)
%Para comparar nombres de columnas y fases
t = lower(char(string(txt)));
t = strrep(t, char(225), 'a'); t = strrep(t, char(233), 'e'); t = strrep(t, char(237), 'i');
t = strrep(t, char(243), 'o'); t = strrep(t, char(250), 'u'); t = strrep(t, char(252), 'u');
t = strrep(t, char(241), 'n');
t = regexprep(t, '[^a-z0-9]', '');
end

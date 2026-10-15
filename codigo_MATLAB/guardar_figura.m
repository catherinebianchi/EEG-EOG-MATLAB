function guardar_figura(fig, ruta)
if exist('exportgraphics', 'file') == 2
    exportgraphics(fig, ruta, 'Resolution', 200);
else
    saveas(fig, ruta);
end
end

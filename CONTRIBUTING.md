# Contribuciones / Contributions

Gracias por contribuir a DWG Version Switch. El repositorio es MIT y admite aportes de cualquiera, independientemente de que use la herramienta de forma personal o comercial.

## Cambios bienvenidos

- Correcciones reproducibles de conversión y protección de archivos originales.
- Soporte para diferentes instalaciones/versiones AutoCAD que tengan permiso de ejecución local.
- Detección más robusta de errores, entidades proxy, XREF y degradaciones al guardar hacia atrás.
- QA con archivos **sintéticos o propios**; pruebas de rendimiento y uso por lotes.
- Mejoras de UX, accesibilidad y documentación en español e inglés.

## Flujo

1. Abre un Issue explicando el problema sin adjuntar dibujos confidenciales.
2. Haz un fork y crea una rama descriptiva.
3. Mantén los cambios pequeños, escribe pruebas y documenta exactamente qué validaste.
4. Ejecuta **npm test** (Node >=18, sin dependencias externas). Para la conversión nativa, ejecuta tu propia batería con AutoCAD licenciado.
5. Abre un Pull Request con evidencia de antes/después, versión AutoCAD y limitaciones conocidas.

**No incluir jamás** planos reales de clientes, nombres, rutas locales privadas, documentación contractual, claves o tokens, binarios propietarios AutoCAD/ODA ni archivos CAD que no puedas redistribuir.

Las pruebas sintéticas de cabecera solo prueban detección, **no** conversión CAD. Un PASS de reapertura NO garantiza equivalencia de entidades.

## Licencias de contribuciones

Al enviar contribuciones aceptas que queden distribuidas bajo la licencia MIT del repositorio. Conserva los avisos de terceros que correspondan. Las marcas PANORAMA, TraficLabPro, Autodesk y AutoCAD pertenecen a sus titulares; su uso no es una concesión de marca.

## ¿Quieres colaborar en un servicio profesional?

Puedes proponer un alcance en Issues o contactar por los canales oficiales del sitio. La base MIT sigue siendo libre. No se prometen funciones comerciales inexistentes.

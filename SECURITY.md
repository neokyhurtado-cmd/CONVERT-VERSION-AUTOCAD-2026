# Política de seguridad / Security policy

## Qué protege este proyecto

El analizador web lee los primeros seis bytes del archivo local y **no los sube**. El conversor invoca AutoCAD Core Console instalado en el dispositivo Windows del usuario, escribe copias nuevas y verifica hashes, formato y reapertura.

## Riesgos conocidos

- Un archivo DWG puede contener objetos personalizados, referencias, contenido malicioso o vínculos inesperados. Abre solo dibujos de fuentes confiables en un entorno CAD actualizado.
- La conversión a versiones antiguas puede perder propiedades o alterar entidades sin que cambie el conteo de objetos.
- El script usa tu licencia de AutoCAD; no incorpora ni administra derechos de terceros.
- Las salidas de QA y los planos siguen siendo responsabilidad del operador.

## Reportar vulnerabilidades

No compartas exploits, credenciales o archivos sensibles en Issues públicos. Usa las opciones privadas de reporte de seguridad que ofrezca GitHub para el repositorio o comunícate por canales oficiales de PANORAMA LAB. Si no hay un canal privado disponible, abre un Issue **sin detalles explotables** para solicitarlo.

## Versiones

Release inicial comunitario: v1.0.0. Se publicarán avisos de seguridad a medida que se identifiquen y verifiquen problemas. No ofrecemos SLA de seguridad para esta edición gratuita.

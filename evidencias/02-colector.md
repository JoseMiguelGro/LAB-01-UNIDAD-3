# Actividad 2 — Que el servidor administre su propia bitácora

## Comandos ejecutados y resultados

```sql
ALTER SYSTEM SET logging_collector = on;
-- Tras reiniciar el servicio:
SELECT name, setting, source FROM pg_settings WHERE name = 'logging_collector';
-- logging_collector | on | configuration file

SELECT pg_current_logfile();
-- log/postgresql-2026-10-25_224920.log

CREATE SCHEMA dba;
REVOKE ALL ON SCHEMA dba FROM PUBLIC;
CREATE VIEW dba.bitacora AS
SELECT t.n AS num, t.linea
FROM regexp_split_to_table(pg_read_file(pg_current_logfile()), E'\n')
WITH ORDINALITY AS t(linea, n)
WHERE t.linea <> '';
```

## Respuestas a las preguntas
1. **¿Por qué `logging_collector` requiere reinicio y `log_statement` solo recarga?**  
   Porque `logging_collector` lanza un proceso auxiliar dedicado en el postmaster encargado de capturar la tubería `stderr` desde el arranque del servidor, mientras que `log_statement` es solo una bandera de configuración que cada proceso *backend* lee en memoria al recibir la señal `SIGHUP` (`pg_reload_conf()`).
2. **¿Qué ventaja tiene que la bitácora se lea con SQL y no con una herramienta del sistema operativo o del contenedor? ¿Qué riesgo introduce?**  
   *Ventaja:* Independiza la consulta de bitácoras del sistema operativo o plataforma de despliegue y evita otorgar acceso SSH o acceso directo al sistema de archivos del servidor al personal que consulta logs.  
   *Riesgo:* `pg_read_file()` permite leer cualquier archivo accesible para el usuario del sistema operativo `postgres` dentro del directorio de datos o rutas relativas; si se otorga mal o la vista es accesible a usuarios no autorizados, expone información confidencial y secretos registrados en las bitácoras.
3. **¿Quién debería poder consultar `dba.bitacora`?**  
   Únicamente el administrador de base de datos (DBA) y los roles específicamente designados para auditoría o seguridad de la información, nunca `PUBLIC` ni usuarios de aplicación.

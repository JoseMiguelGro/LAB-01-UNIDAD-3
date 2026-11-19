--Actividad 1: Revisar la configuración de registro por defecto
SELECT name, setting, source FROM pg_settings
WHERE name IN ('log_destination', 'logging_collector', 'log_directory', 'log_filename',
'log_connections', 'log_disconnections', 'log_line_prefix',
'log_statement', 'log_min_error_statement', 'log_timezone') ORDER BY name;

-- Actividad 2: Activar el colector de bitácora y crear la vista dba.bitacora
ALTER SYSTEM SET logging_collector = on;
-- Requiere reinicio del servicio PostgreSQL antes de ejecutar lo siguiente:

SELECT name, setting, source FROM pg_settings WHERE name = 'logging_collector';
SELECT pg_current_logfile();

CREATE SCHEMA IF NOT EXISTS dba;
REVOKE ALL ON SCHEMA dba FROM PUBLIC;

--En Contenedores y Linux
CREATE OR REPLACE VIEW dba.bitacora AS
SELECT t.n AS num, t.linea
FROM regexp_split_to_table(pg_read_file(pg_current_logfile()), E'\n')
WITH ORDINALITY AS t(linea, n)
WHERE t.linea <> '';

--En Windows
CREATE OR REPLACE VIEW dba.bitacora AS
SELECT t.n AS num, t.linea
FROM regexp_split_to_table(
    convert_from(pg_read_binary_file(pg_current_logfile()), 'WIN1252'),
    E'\r?\n'
) WITH ORDINALITY AS t(linea, n)
WHERE t.linea <> '';


SELECT num, linea FROM dba.bitacora ORDER BY num DESC LIMIT 10;

SELECT linea FROM dba.bitacora WHERE linea ILIKE '%update%';

SELECT linea FROM dba.bitacora WHERE linea ~ '(FATAL|ERROR)';

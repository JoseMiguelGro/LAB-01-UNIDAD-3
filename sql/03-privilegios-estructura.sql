-- Actividad 6: Cambios de privilegios, estructura y prueba de exposición de secretos
REVOKE UPDATE ON clientes FROM soporte_ana;
GRANT UPDATE ON clientes TO app_ventas;
ALTER TABLE clientes ADD COLUMN IF NOT EXISTS segmento VARCHAR(20);

-- Prueba de fuga de contraseña en bitácora (no usar en producción):
CREATE ROLE rol_temporal LOGIN PASSWORD 'Temporal_Practica_2026';
DROP ROLE rol_temporal;

SELECT linea FROM dba.bitacora WHERE linea LIKE '%statement:%' ORDER BY num;

ALTER SYSTEM SET log_statement = 'mod';
SELECT pg_reload_conf();

SELECT linea FROM dba.bitacora
WHERE linea LIKE '%log_statement%' OR linea LIKE '%user=app_ventas%statement:%'
ORDER BY num;

DROP ROLE soporte_ana;

SELECT linea FROM dba.bitacora

SELECT pid, usename, application_name, client_addr, backend_start, state, left(query, 30) AS query
FROM pg_stat_activity
WHERE backend_type = 'client backend'
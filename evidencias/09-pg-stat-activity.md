# Actividad 9 — Sesiones activas con `pg_stat_activity`

## Comandos ejecutados y resultados

```sql
SELECT pid, usename, application_name, client_addr, backend_start, state, left(query, 30) AS query
FROM pg_stat_activity
WHERE backend_type = 'client backend';
-- pid: 189 | usename: soporte_ana | application_name: reporte-mensual | client_addr: 127.0.0.1 | state: active | query: SELECT pg_sleep(90)

SELECT linea FROM dba.bitacora WHERE linea LIKE '%[189]%' ORDER BY num;
```
Al terminar la consulta, el PID `189` desaparece de `pg_stat_activity`.

## Respuestas a las preguntas
1. **¿Qué columna permite relacionar una sesión con sus líneas de bitácora?**  
   La columna `pid` de `pg_stat_activity`, que corresponde al marcador `[%p]` configurado en `log_line_prefix`.
2. **Después de que termina el reporte, ¿qué fuente conserva evidencia de que existió?**  
   La **bitácora del servidor** (`dba.bitacora`), donde quedan registradas las líneas de conexión y desconexión asociadas a ese PID. `pg_stat_activity` solo muestra las sesiones activas en tiempo real.
3. **¿Por qué `client_addr` aparece vacío en la sesión del administrador?**  
   Porque el administrador se conectó localmente a través de un socket de dominio Unix (`local`), no mediante una conexión de red TCP/IP, por lo que no existe una dirección IP de cliente.

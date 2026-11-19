# Actividad 4 — Configurar la bitácora

## Comandos ejecutados y resultados

```sql
ALTER SYSTEM SET log_connections = on;
ALTER SYSTEM SET log_disconnections = on;
ALTER SYSTEM SET log_line_prefix = '%m [%p] user=%u db=%d app=%a client=%h ';
ALTER SYSTEM SET log_statement = 'ddl';
SELECT pg_reload_conf();
```

## Respuestas a las preguntas
1. **¿Por qué el proceso que registra el cambio es el principal y no tu sesión?**  
   Porque `pg_reload_conf()` envía una señal `SIGHUP` al proceso principal (*postmaster*, PID 1), el cual relee `postgresql.conf` y `postgresql.auto.conf`, aplica los nuevos valores globales y emite los mensajes `parameter ... changed to ...` antes de propagar la señal a los procesos hijos.
2. **¿Qué pasaría si alguien ejecutara `ALTER SYSTEM SET log_statement = 'none'`? ¿Quedaría rastro?**  
   Sí quedaría rastro en dos momentos: primero, si `log_statement` estaba en `'ddl'`, `'mod'` o `'all'`, se registrará la propia sentencia `ALTER SYSTEM SET log_statement = 'none'`; segundo, al ejecutar `pg_reload_conf()`, el proceso principal registrará `LOG: parameter "log_statement" changed to "none"`.
3. **¿Por qué no se recomienda editar `postgresql.auto.conf` a mano?**  
   Porque ese archivo es administrado exclusivamente por el comando `ALTER SYSTEM` de PostgreSQL; una edición manual con errores de sintaxis puede impedir que el servidor recargue su configuración o arranque tras un reinicio, y cualquier cambio manual puede ser sobrescrito por futuros comandos `ALTER SYSTEM`.

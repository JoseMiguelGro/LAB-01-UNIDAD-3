# Actividad 7 — Modificaciones de datos: `ddl` frente a `mod`

## Comandos ejecutados y resultados

Con `log_statement = 'ddl'`:
```bash
psql "postgresql://app_ventas:<REDACTED>@127.0.0.1/comercial?application_name=app-ventas-web" -c "UPDATE clientes SET rfc = 'GAMA780912XYZ' WHERE id = 3"
```
Solo registró conexión y desconexión, sin el `UPDATE`.

Tras cambiar a `log_statement = 'mod'`:
```bash
psql "postgresql://app_ventas:<REDACTED>@127.0.0.1/comercial?application_name=app-ventas-web" -c "UPDATE clientes SET telefono = '6679990000' WHERE id = 3" -c "SELECT nombre, rfc FROM clientes WHERE id = 3"
```
Resultado en bitácora:
```text
"	ALTER SYSTEM SET log_statement = 'ddl';"
"2026-11-18 21:42:00.911 CST [19372] user=postgres db=LaboratorioDBA app=pgAdmin 4 - CONN:8594320 client=::1 LOG:  sentencia: ALTER SYSTEM SET log_statement = 'ddl';"
"2026-11-18 21:42:00.912 CST [19372] user=postgres db=LaboratorioDBA app=pgAdmin 4 - CONN:8594320 client=::1 SENTENCIA:  ALTER SYSTEM SET log_statement = 'ddl';"
"2026-11-18 21:42:06.869 CST [19372] user=postgres db=LaboratorioDBA app=pgAdmin 4 - CONN:8594320 client=::1 LOG:  sentencia: ALTER SYSTEM SET log_statement = 'ddl';"
"2026-11-18 21:51:33.843 CST [19372] user=postgres db=LaboratorioDBA app=pgAdmin 4 - CONN:8594320 client=::1 LOG:  sentencia: ALTER SYSTEM SET log_statement = 'mod';"
```

## Respuestas a las preguntas
1. **¿Qué nivel habría registrado la lectura del RFC? ¿Qué costo tendría en un servidor con miles de consultas por minuto?**  
   El nivel `log_statement = 'all'`. En un servidor con miles de consultas por minuto generaría un crecimiento masivo del tamaño de los archivos de bitácora (consumo acelerado de disco), contención de entrada/salida (I/O) por escritura continua en disco y degradación del rendimiento general del motor, además de dificultar el análisis forense por exceso de ruido.
2. **¿Qué le falta a esta bitácora para revertir el cambio con certeza?**  
   Le falta el **valor anterior** del dato (`telefono` antes de ser actualizado a `'6679990000'`), ya que `log_statement` solo registra el texto de la sentencia ejecutada, no el estado previo de las filas afectadas.

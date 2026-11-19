# Actividad 11 y 12 — Función, disparador e incidente auditado

## Respuestas a las preguntas de la Actividad 11
1. **¿Por qué se ejecuta `REVOKE ALL ON FUNCTION ... FROM PUBLIC` si el disparador seguirá funcionando para `app_ventas`?**  
   Para impedir que usuarios ordinarios invoquen manualmente la función de disparador desde SQL fuera del contexto de un evento real sobre la tabla `clientes`. El motor ejecuta internamente los disparadores asociados a la tabla sin requerir permiso `EXECUTE` explícito del usuario que realiza el DML.
2. **¿Qué pasaría si la función no fuera `SECURITY DEFINER`? Formula una hipótesis antes de la Actividad 12.**  
   *Hipótesis:* La función se ejecutaría con los privilegios de `app_ventas` (`SECURITY INVOKER`). Como `app_ventas` no tiene permisos sobre el esquema `auditoria` ni sobre `auditoria.cambios_clientes`, el disparador fallaría con `ERROR: permission denied for schema auditoria` y abortaría toda la transacción `UPDATE` de la aplicación.
3. **Consulta `dba.bitacora`. ¿Quedó registrada la creación del esquema, la tabla, la función y el disparador? ¿Por qué?**  
   No quedó registrada en `dba.bitacora` porque en la Actividad 7 se cambió `log_statement` de `'ddl'` a `'mod'`, y el nivel `'mod'` registra únicamente sentencias de manipulación de datos (`INSERT`, `UPDATE`, `DELETE`, `TRUNCATE`, `COPY`), omitiendo las sentencias DDL (`CREATE SCHEMA/TABLE/FUNCTION/TRIGGER`).

## Resultados y respuestas a las preguntas de la Actividad 12

Resultado de la consulta de comparación campo por campo:
```text
id_evento | momento                       | usuario_sesion | ip_cliente | campo | antes         | despues
----------+-------------------------------+----------------+------------+-------+---------------+--------------
1         | 2026-10-25 22:50:52.903439+00 | app_ventas     | 127.0.0.1  | rfc   | GAMA780912XYZ | GAMA780912ZZZ
```

1. **Compara tu hipótesis de la Actividad 11 con este resultado.**  
   Se confirma plenamente: gracias a `SECURITY DEFINER`, `app_ventas` pudo disparar la inserción en `auditoria.cambios_clientes` (donde `usuario_efectivo` fue `postgres` y `usuario_sesion` fue `app_ventas`), pero cuando `app_ventas` intentó hacer `SELECT * FROM auditoria.cambios_clientes` directamente, recibió `ERROR: permission denied for schema auditoria`.
2. **Escribe la sentencia `UPDATE` que restauraría el valor anterior.**  
   ```sql
   UPDATE clientes
   SET rfc = 'GAMA780912XYZ'
   WHERE id = 3;
   ```
   *(Nota: Si se desea restaurar el RFC original inicial previo al incidente de la Actividad 3, el valor sería `'GAMA780912GHI'`).*
3. **¿Qué columna conserva más valor para una investigación: `aplicacion` o `ip_cliente`? ¿Cuál puede falsificar el cliente con más facilidad?**  
   `ip_cliente` conserva mayor valor probatorio porque proviene de la conexión de red TCP evaluada por el servidor. `aplicacion` (`application_name`) puede falsificarse con total facilidad porque es una cadena de texto arbitraria que el propio cliente envía en los parámetros de conexión.

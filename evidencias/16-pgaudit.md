# Actividad 18 y 19 — `pgaudit` (Parte C opcional) 

## Configuración aplicada y resultados observados

```sql
ALTER SYSTEM SET shared_preload_libraries = 'pgaudit';
-- Tras reiniciar el servidor:
CREATE EXTENSION pgaudit;

CREATE ROLE auditor_datos NOLOGIN;
GRANT SELECT (rfc, telefono), UPDATE (rfc, telefono) ON clientes TO auditor_datos;

ALTER SYSTEM SET pgaudit.log = 'role, ddl';
ALTER SYSTEM SET pgaudit.role = 'auditor_datos';
ALTER SYSTEM SET pgaudit.log_relation = on;
SELECT pg_reload_conf();
```

Registros capturados en bitácora:
```text
user=app_ventas db=comercial app=app-ventas-web client=127.0.0.1 LOG:  AUDIT: OBJECT,1,1,READ,SELECT,TABLE,public.clientes,"SELECT nombre, rfc FROM clientes WHERE id = 3",<not logged>
user=app_ventas db=comercial app=app-ventas-web client=127.0.0.1 LOG:  AUDIT: OBJECT,2,1,READ,SELECT,TABLE,public.clientes,SELECT * FROM clientes WHERE id = 4,<not logged>
user=app_ventas db=comercial app=app-ventas-web client=127.0.0.1 LOG:  AUDIT: OBJECT,3,1,WRITE,UPDATE,TABLE,public.clientes,UPDATE clientes SET rfc = 'LOAA850315XXX' WHERE id = 1,<not logged>
user=postgres db=comercial app=psql client=[local] LOG:  AUDIT: SESSION,1,1,ROLE,GRANT,TABLE,,GRANT SELECT ON clientes TO soporte_ana,<not logged>
```

## Respuestas a las preguntas
1. **¿Por qué no apareció `SELECT nombre, ciudad ...`? ¿Por qué sí apareció `SELECT * ...`?**  
   - `SELECT nombre, ciudad ...` no apareció porque `auditor_datos` solo tiene privilegios sobre las columnas sensibles `rfc` y `telefono`; como ninguna de esas columnas fue referenciada en la consulta, el filtro de auditoría de objeto la ignoró.  
   - `SELECT * ...` sí apareció porque el asterisco expande todas las columnas de `clientes`, incluyendo `rfc` y `telefono`, activando la auditoría de objeto.
2. **¿Por qué no apareció `UPDATE ... ciudad ...`?**  
   Porque la sentencia modificó únicamente la columna `ciudad`, sobre la cual `auditor_datos` no tiene otorgado privilegio `UPDATE`. `pgaudit` filtra con precisión a nivel de columna afectada.
3. **¿Qué diferencia de volumen esperarías frente a `log_statement = 'all'`?**  
   Una reducción drástica de volumen en entornos reales: mientras `log_statement = 'all'` registra absolutamente todas las consultas (`SELECT`, `SHOW`, consultas de catálogo y tablas no sensibles), `pgaudit` en modo objeto registra **únicamente** las operaciones que tocan tablas o columnas específicamente marcadas como sensibles, minimizando el consumo de disco y el ruido operativo.
4. **El README oficial advierte que `pgaudit` no puede auditar de forma confiable a los superusuarios. ¿Qué implica para la separación de funciones?**  
   Implica que un superusuario puede modificar los parámetros de `pgaudit` (`SET pgaudit.log = 'none'`), alterar los privilegios del rol auditor o deshabilitar la extensión en su sesión. Por ello, las cuentas con atributo `SUPERUSER` deben restringirse al mínimo absoluto, no usarse para operación cotidiana, y combinarse con controles externos de custodia de bitácoras y segregación administrativa.

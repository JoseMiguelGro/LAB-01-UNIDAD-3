# Actividad 14 — Intentar manipular la auditoría

## Resultados observados

Intento de `app_ventas`:
```text
ERROR: permission denied for schema auditoria
ERROR: must be owner of table clientes
```
Manipulación por `postgres`:
```text
[260] user=postgres db=comercial app=psql client=[local] LOG:  statement: ALTER TABLE clientes DISABLE TRIGGER trg_auditoria_clientes
[260] user=postgres db=comercial app=psql client=[local] LOG:  statement: UPDATE clientes SET rfc = 'GAMA780912GHI' WHERE id = 3
[260] user=postgres db=comercial app=psql client=[local] LOG:  statement: ALTER TABLE clientes ENABLE TRIGGER trg_auditoria_clientes
```

## Respuestas a las preguntas
1. **¿Qué evidencia permite detectar que hubo un cambio sin auditar?**  
   La **bitácora del servidor** (`dba.bitacora`), donde quedaron registradas las sentencias `ALTER TABLE clientes DISABLE TRIGGER trg_auditoria_clientes`, el `UPDATE` ejecutado en esa ventana y la posterior reactivación `ENABLE TRIGGER`, además de la discrepancia entre el estado actual de la tabla `clientes` y el último estado registrado en `auditoria.cambios_clientes`.
2. **¿Qué control administrativo (no técnico) reduciría este riesgo?**  
   La implementación de **segregación de funciones (SoD)** mediante roles organizacionales separados (que quien administra la operación de la base de datos no sea quien custodia los servidores de bitácoras ni realiza las auditorías), acompañada de revisiones periódicas independientes, aprobación formal de cambios (gestión de cambios) y acuerdos de confidencialidad/responsabilidad.
3. **Relaciona esta actividad con el principio de separación de funciones de la Unidad II.**  
   En la Unidad II se separaron los roles operativos (`app_ventas`, `soporte_ana`) del administrador (`postgres`). Esta actividad demuestra que la separación debe extenderse al plano de la **supervisión y evidencia**: ningún mecanismo interno en el propio servidor protege contra un superusuario con control total, por lo que las bitácoras deben reenviarse en tiempo real a un repositorio externo (SIEM / servidor syslog dedicado) administrado por un equipo independiente de Seguridad Informática.

# Actividad 15 — Límites: lecturas y volumen

## Resultados observados

```text
lineas_bitacora: 1
operacion | count
----------+------
DELETE    | 1
INSERT    | 1
UPDATE    | 6
lecturas_soporte: 0
```

## Respuestas a las preguntas
1. **Si `clientes` tuviera un millón de registros, ¿qué ocurriría con la auditoría tras un `UPDATE` sin `WHERE`?**  
   La bitácora del servidor escribiría **una sola línea** con la sentencia `UPDATE`, mientras que el disparador `FOR EACH ROW` insertaría **un millón de filas nuevas** en `auditoria.cambios_clientes` dentro de la misma transacción. Esto provocaría una fuerte degradación del tiempo de respuesta, bloqueo prolongado, crecimiento explosivo del almacenamiento (duplicando el registro completo en formato `JSONB` antes y después por cada fila) y saturación de WAL/replicación.
2. **Propón quién podría autorizar la depuración de `auditoria.cambios_clientes`.**  
   La depuración o archivado histórico debe requerir autorización conjunta (control dual) del **Oficial de Seguridad / Auditoría Interna** y del **Propietario del Dato (Área de Negocio / Legal)**, ejecutada bajo un procedimiento documentado y respaldado en almacenamiento inmutable externo, nunca por decisión unilateral del DBA operativo.
3. **¿Por qué `log_statement = 'all'` puede convertir la bitácora en un nuevo depósito de datos sensibles?**  
   Porque registra el texto íntegro de todas las consultas y parámetros literales (`SELECT`, `INSERT`, `UPDATE`), incluyendo búsquedas por RFC, CURP, correos, teléfonos, contraseñas en texto claro o tokens enviados en las consultas SQL. Si la bitácora no tiene controles de acceso tan estrictos como la propia base de datos, se convierte en una fuga secundaria de datos personales y credenciales.

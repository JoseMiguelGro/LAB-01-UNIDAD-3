# Actividad 13 — Altas y bajas 

## Resultados observados

```text
id_evento | usuario_sesion | aplicacion | ip_cliente | operacion | id_cliente | rfc_antes     | rfc_despues
----------+----------------+------------+------------+-----------+------------+---------------+--------------
1         | app_ventas     | app-ventas-web | 127.0.0.1 | UPDATE  | 3          | GAMA780912XYZ | GAMA780912ZZZ
2         | postgres       | psql       |            | INSERT    | 6          |               | RUPE950101AAA
3         | postgres       | psql       |            | DELETE    | 6          | RUPE950101AAA |
```

## Respuestas a las preguntas
1. **El cliente Pedro Ruiz ya no existe en `clientes`. ¿Dónde queda evidencia de que existió y de sus datos?**  
   En la tabla `auditoria.cambios_clientes`, específicamente en el registro `id_evento = 2` (`INSERT`, dentro de `valores_despues`) y en el registro `id_evento = 3` (`DELETE`, dentro de `valores_antes`).
2. **¿Por qué `ip_cliente` está vacía en los eventos 2 y 3?**  
   Porque las operaciones se ejecutaron desde la sesión local del administrador conectada mediante socket de dominio Unix (`local`), donde `inet_client_addr()` devuelve `NULL` al no haber dirección IP remota.
3. **La política de retención de la Unidad II pedía eliminar datos cuando ya no fueran necesarios. ¿Qué conflicto aparece? ¿Quién debe resolverlo?**  
   Aparece una tensión directa entre el principio de minimización/supresión de datos personales (derecho de cancelación o fin de retención operativa) y la obligación de conservar evidencia íntegra e inmutable para auditoría y cumplimiento fiscal/legal. Este conflicto debe resolverlo el área de **Gobierno de Datos / Cumplimiento Legal (DPO)** junto con el **Propietario del Dato**, definiendo plazos legales de retención de bitácoras y procedimientos formales de anonimización o expurgo autorizado.

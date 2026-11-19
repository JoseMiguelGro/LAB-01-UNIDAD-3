# Actividad 6 — Cambios de privilegios y de estructura 

## Comandos ejecutados y resultados

```sql
REVOKE UPDATE ON clientes FROM soporte_ana;
GRANT UPDATE ON clientes TO app_ventas;
ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20);
CREATE ROLE rol_temporal LOGIN PASSWORD '<REDACTED>';
DROP ROLE rol_temporal;
```

## Respuestas a las preguntas
1. **¿Qué tipo de evento es cada una de las tres primeras sentencias (privilegio o estructura)?**  
   - `REVOKE UPDATE ON clientes FROM soporte_ana`: Evento de **Privilegio** (DCL).  
   - `GRANT UPDATE ON clientes TO app_ventas`: Evento de **Privilegio** (DCL).  
   - `ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20)`: Evento de **Estructura** (DDL).
2. **¿Por qué `GRANT` y `REVOKE` quedan registrados con `log_statement = 'ddl'`?**  
   Porque en la clasificación interna de PostgreSQL para `log_statement`, el nivel `'ddl'` abarca no solo las sentencias de definición de esquemas y objetos (`CREATE`, `ALTER`, `DROP`), sino también las sentencias de control de acceso y gestión de roles (`GRANT`, `REVOKE`, `CREATE/ALTER/DROP ROLE`).
3. **Si la bitácora contiene contraseñas, ¿quién debería poder leerla? Relaciónalo con la gestión de secretos de la Unidad II.**  
   Únicamente personal altamente privilegiado y autorizado bajo necesidad de saber (DBA/Seguridad), y aun así los secretos nunca deben almacenarse en claro. En la Unidad II se estableció que las credenciales deben gestionarse mediante mecanismos seguros (como `.pgpass`, variables de entorno protegidas, gestores de secretos o `\password` que calcula el hash SCRAM en el cliente), evitando incrustar contraseñas literales en sentencias SQL que puedan quedar persistidas en historial de comandos o bitácoras.

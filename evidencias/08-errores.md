# Actividad 8 — Errores y operaciones rechazadas 

## Comandos ejecutados y resultados

```bash
psql "postgresql://soporte_ana:<REDACTED>@127.0.0.1/comercial" -c "DELETE FROM clientes WHERE id = 5"
# ERROR: permission denied for table clientes
```
```sql
DROP ROLE soporte_ana;
-- ERROR: role "soporte_ana" cannot be dropped because some objects depend on it
-- DETAIL: privileges for table clientes
```

## Respuestas a las preguntas
1. **¿El intento de `soporte_ana` causó algún daño? ¿Por qué debe auditarse de todos modos?**  
   No causó daño en los datos porque el motor bloqueó la operación. Debe auditarse porque constituye un indicador temprano de posible abuso de funciones, compromiso de credenciales o intento de escalamiento/sabotaje interno; detectar intentos denegados permite actuar antes de que el actor encuentre un vector exitoso.
2. **¿Qué diferencia hay entre un error de autorización (esta actividad) y uno de autenticación (Actividad 5)?**  
   - *Autenticación (Actividad 5):* El usuario no logra demostrar quién es (credenciales inválidas o rol inexistente); se rechaza antes de abrir la sesión (`FATAL: password authentication failed`).  
   - *Autorización (Actividad 8):* El usuario ya se autenticó legítimamente y tiene sesión activa, pero intenta ejecutar una acción sobre un objeto para el cual no tiene privilegios asignados (`ERROR: permission denied`).
3. **¿Qué indica el error de `DROP ROLE` sobre el orden correcto para dar de baja a un usuario?**  
   Indica que antes de eliminar un rol se deben revocar todos sus privilegios explícitos sobre objetos (`REVOKE ALL ON ... FROM rol`) y reasignar o eliminar los objetos de su propiedad (`REASSIGN OWNED BY ...` / `DROP OWNED BY ...`), garantizando una baja limpia y controlada.

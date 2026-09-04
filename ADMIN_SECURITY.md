# Seguridad administrativa

## Modelo aplicado

- Los roles `support`, `moderator` y `admin` existen exclusivamente como
  Firebase Authentication Custom Claims.
- Los perfiles de Firestore no admiten campos de roles ni otros campos ocultos.
- Firestore, Storage y las Cloud Functions privilegiadas exigen MFA.
- Las Cloud Functions exigen además que el acceso administrativo se haya
  autenticado durante los últimos 15 minutos.
- Cada cambio de rol queda registrado en `administrativeAudit`; ningún cliente
  puede escribir esa colección.
- Soporte solo accede a tickets y sus evidencias. Moderación solo accede a
  reseñas, denuncias y auditoría de moderación. El administrador conserva las
  operaciones excepcionales expresamente declaradas, no un acceso global.

## Propietario técnico e IAM

Usar una cuenta de Google separada, protegida con MFA, como propietario técnico.
No usar una cuenta cotidiana ni guardar claves JSON de cuentas de servicio en el
repositorio. En Google Cloud IAM se deben conceder solo los permisos necesarios:

- Administración de Firebase Authentication para gestionar Custom Claims.
- Escritura de Firestore necesaria para registrar la auditoría.
- Permisos de despliegue únicamente a quien realmente despliega.

Evitar entregar el rol global `Owner` a cuentas de soporte o moderación. Esos
usuarios operan mediante la aplicación y sus Custom Claims, no mediante IAM.

## Crear el primer administrador o recuperar el acceso

La primera asignación se ejecuta localmente por el propietario técnico con
Application Default Credentials:

```powershell
gcloud auth application-default login
cd functions
npm run admin:role -- UID_DEL_USUARIO admin --confirm
```

Para asignar soporte o moderación, sustituir `admin` por `support` o `moderator`.
Para revocar todos los roles administrativos:

```powershell
npm run admin:role -- UID_DEL_USUARIO none --confirm
```

El correo del usuario debe estar verificado para recibir un rol. El comando
revoca las sesiones existentes; el usuario debe iniciar sesión nuevamente y
completar MFA para obtener acceso.

## Operación normal

Después del bootstrap, un administrador con MFA puede llamar a
`setAdministrativeRole` indicando `targetUid`, un rol y una razón de al menos
10 caracteres. Un administrador no puede cambiar su propio rol. La revocación o
recuperación de emergencia se hace mediante el comando del propietario técnico.

Antes de activar estas reglas en producción:

1. Habilitar MFA para las cuentas administrativas en Firebase Authentication.
2. Registrar una segunda fase en cada cuenta de soporte, moderación y administración.
3. Crear el primer administrador con el procedimiento anterior.
4. Ejecutar todas las pruebas locales.
5. Desplegar Functions y reglas en una misma ventana controlada.
6. Confirmar acceso con MFA y confirmar que el acceso sin MFA sea rechazado.

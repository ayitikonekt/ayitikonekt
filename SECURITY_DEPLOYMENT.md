# Despliegue de seguridad de Firebase

Los cambios de esta carpeta bloquean las escrituras sensibles desde la app y
las trasladan a Cloud Functions autenticadas.

## Requisitos

- Firebase CLI con una sesión iniciada.
- Node.js 22.
- Proyecto Firebase `ayitikonekt` en plan Blaze para desplegar Functions.

## Preparación

```bash
flutter pub get
cd functions
npm install
cd ..
```

## Prueba local recomendada

```bash
firebase emulators:start --only auth,firestore,storage,functions
```

En otra terminal, ejecutar la aplicación conectada explícitamente a los
emuladores:

```bash
flutter run --dart-define=USE_FIREBASE_EMULATORS=true
```

Para un teléfono físico, indicar la IP local del equipo que ejecuta Firebase:

```bash
flutter run --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=FIREBASE_EMULATOR_HOST=192.168.1.100
```

El teléfono y el equipo deben estar en la misma red. Sustituir la IP del ejemplo
por la dirección IPv4 real del equipo.

Antes de conectar una compilación de producción, probar con dos cuentas:

1. Cada cuenta puede editar únicamente su perfil.
2. Solo el vendedor puede editar o eliminar su producto.
3. Favoritos, vistas, notificaciones y reputación funcionan mediante Functions.
4. Favoritos y notificaciones ajenos no pueden leerse.
5. Los tickets y adjuntos solo son visibles por el autor o un administrador.
6. Storage rechaza archivos no permitidos o demasiado grandes.

## Despliegue

```bash
firebase deploy --project ayitikonekt --only firestore:rules,storage,functions
```

No desplegar únicamente las reglas antes de desplegar las Functions y publicar
una versión de la app que use `cloud_functions`: las versiones antiguas todavía
intentan escribir directamente los campos que las reglas nuevas bloquean.

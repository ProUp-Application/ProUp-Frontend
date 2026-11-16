# Guía de demostración para la sustentación

Recorrido de unos 6 minutos que muestra las mejoras pedidas por el asesor metodológico.
Probado en el emulador Android `Medium_Phone_API_36.0` y en el APK.

## 1. Antes de empezar (SUS-01, SUS-02)

| Opción | Cuándo usarla | Cómo |
|---|---|---|
| Celular con el APK | Opción principal | Instala el APK de producción (backend en Railway). Activa el micrófono y la cámara la primera vez que la app los pida. |
| Emulador Android | Si falla el celular | Android Studio → Device Manager → `Medium_Phone_API_36.0`. En las opciones del emulador, habilita **Microphone → Virtual microphone uses host audio input** para grabar respuestas. |
| Video de respaldo | Si fallan ambos | `video_respaldo_demo.mp4` (grabado del emulador). |

Revisa 10 minutos antes: internet estable, batería, volumen del teléfono (para "Escuchar" la pregunta) y que el backend responda en `/health`.

## 2. Datos de prueba (SUS-03)

- Cuenta demo con historial: **demo@proup.pe / Demo2026** (se crea con `npm run db:seed-demo` en el backend; datos ficticios).
- CV de ejemplo con errores intencionales: `datos_demo/cv_demo.docx` y `datos_demo/cv_demo.txt`.
- Vacante de ejemplo: `datos_demo/vacante_demo.txt`.
- Fotos: usa tres fotos propias (selfie, medio cuerpo y cuerpo entero). No incluimos fotos de personas en el repositorio.

## 3. Recorrido (SUS-05)

1. **Registro (30 s).** Crear cuenta → escribir una contraseña débil y mostrar la lista de requisitos marcándose en tiempo real → tocar "¿Qué datos usamos y para qué?".
2. **Análisis de imagen (90 s).** Escanear → mostrar las pautas previas y los 4 tipos de foto.
   - Selfie: el resultado dice "Foto: Primer plano" y **Vestimenta / Postura: No evaluado**, con el motivo.
   - Tocar una categoría para ver "por qué" (evidencia visible) y la tarjeta de formalidad justificada.
3. **Simulador por voz (2 min).** Simulador → Elevator Pitch → "Escuchar" la consigna → "Hablando" → Grabar → mostrar el temporizador de 60 s → Detener → revisar/corregir la transcripción → Finalizar → comentarios por pregunta con el tiempo usado.
   - Mencionar el alcance: se evalúa el contenido transcrito, no la pronunciación ni la entonación.
4. **Mejorar mi CV (90 s).** Inicio → Mejorar mi CV → adjuntar `cv_demo.docx` → revisión por secciones, errores y pautas ATS (con "¿Por qué importa?" y el descargo) → Generar versión mejorada → mostrar "Datos descartados" si aparece → editar un logro → Descargar en Word.
   - Opcional: "Comparar con una vacante" con `vacante_demo.txt`.
5. **Progreso (30 s).** Mi progreso → "Tus resultados · Solo tú" frente a "Referencia de la comunidad · General" → historial con pestañas Imagen / Entrevistas → abrir un registro.

## 4. Si algo falla durante la demo

| Síntoma | Qué hacer |
|---|---|
| La transcripción tarda o falla | Mostrar el botón "Reintentar transcripción" o cambiar a "Escribiendo". |
| La IA no responde (consejos o CV) | La app muestra el respaldo automático; continuar y explicarlo como degradación controlada. |
| No hay internet | Cambiar al video de respaldo. |

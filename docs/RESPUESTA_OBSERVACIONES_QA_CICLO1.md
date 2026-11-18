# Respuesta a las observaciones del primer ciclo de QA

Informe de evidencias del grupo evaluador (Garayar Mori y Huarcaya Chávez), primer ciclo del 12/11/2026: 38 casos, 35 aprobados, 3 observados y 4 hallazgos. Este documento explica qué cambiamos por cada hallazgo y cómo comprobarlo en el segundo ciclo.

Los cambios están en la rama `feat/mejoras-asesor-metodologico` de ambos repositorios.

## H01 · Tiempo del análisis en un teléfono real (CP020, RNF-01)

**Qué cambió.** La app mide cuánto tarda el análisis en el teléfono: la lectura de la foto, los tres modelos de ML Kit (rostro, escena y pose) y el cálculo de puntajes.

- En la pantalla "Tu análisis", debajo del nivel, aparece "Procesado en tu teléfono en 1,4 s".
- El valor en milisegundos se guarda en `analysis_results.raw_metrics.analysisMs`, así que también aparece al reabrir el análisis desde el historial.

Archivos: `lib/features/analysis/presentation/ondevice/vision_mlkit.dart` (cronómetro), `vision_types.dart` (`withAnalysisMs`), `data/models/analysis_models.dart` y `screens/results_screen.dart`. La lógica de puntajes no cambió.

**Cómo verificarlo en un celular de gama media.**

1. Instalar el APK en un Android de gama media (por ejemplo, con 4 GB de RAM y un procesador Snapdragon serie 6 o Helio G).
2. Escanear → Analizar mi imagen, con una selfie y con una foto de cuerpo entero.
3. Anotar el tiempo de "Procesado en tu teléfono en … s". RNF-01 se cumple si es menor a 3 s.
4. Opcional: consultar la base, por ejemplo `select raw_metrics->>'analysisMs' from analysis_results order by created_at desc limit 5;`.

La primera vez que se usa la app, ML Kit carga los modelos y ese análisis tarda más. Conviene reportar el segundo análisis o el promedio de tres.

## H02 · Repetir el registro con la misma cuenta (CP001)

**Qué cambió.** Agregamos un script de QA en el backend que borra una cuenta de prueba con todos sus datos: perfil, consentimientos, análisis, recomendaciones, entrevistas y chats.

```bash
npm run qa:reset-account -- prueba.cp@correo.com --dry-run   # solo muestra qué tiene
npm run qa:reset-account -- prueba.cp@correo.com             # la borra
```

- Por seguridad, sin `--force` solo acepta correos que parecen de prueba: `@correo.com`, `@example.com`, o con "prueba", "test", "qa" o "demo".
- Usa la base de `DATABASE_URL`.
- Archivos: `ProUp-Backend/scripts/qa-reset-account.ts` y la sección "Apoyo para QA" del README.

**Cómo verificarlo.** Si el script no se puede ejecutar contra la base de Railway, nos piden la limpieza antes del ciclo o se sigue usando "Perfil → Eliminar mi cuenta". Otra opción es usar un correo con sufijo por ejecución, por ejemplo `prueba.cp+c2@correo.com`.

## H03 · Probar la respuesta de respaldo sin apagar el LLM (CP036)

**Qué cambió.** Agregamos un modo de prueba que simula la caída del LLM solo en una petición:

- Se arranca el backend con `QA_LLM_FAILURE_SIMULATION=true`.
- Cada petición que envíe la cabecera `x-simulate-llm-failure: 1` se comporta como si Groq no respondiera.
- Con eso se ejecuta el respaldo real: el asesor responde por palabras clave, y lo mismo pasa en las recomendaciones, la entrevista y el CV.
- Sin la variable, la cabecera se ignora. Es el valor por defecto y el de producción.

Archivos: `src/lib/qaContext.ts`, `src/lib/llm.ts`, `src/app.ts` y `test/qa-llm-failure.test.ts`.

**Cómo verificarlo.** En un backend de QA con la variable activa, crear una sesión de chat y enviar el mensaje con la cabecera:

```bash
curl -X POST "$API/chat/sessions/$SESION/messages" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -H "x-simulate-llm-failure: 1" \
  -d '{"content":"¿Cómo puedo prepararme para una entrevista?"}'
```

La respuesta es la de respaldo: "Usa el método STAR (Situación, Tarea, Acción, Resultado)…". Sin la cabecera responde el LLM.

El mensaje "No pude responder ahora. Intenta de nuevo." de la app aparece cuando no llega ninguna respuesta del servidor. Se prueba como en CP038, cortando la red.

## H04 · Avisos de "sin conexión" que desaparecían (CP010, CP019, CP027, CP032, CP034, CP038)

**Qué cambió.** Los errores de conexión ya no usan un aviso temporal (SnackBar). Ahora aparece un aviso fijo en la parte superior de la pantalla con el título "Sin conexión", el mismo mensaje de antes y los botones **Reintentar** y **Cerrar**. El aviso se queda hasta que el reintento funciona o el usuario lo cierra.

| Pantalla | Mensaje (igual que en la matriz) | Qué hace "Reintentar" |
|---|---|---|
| Simulador: elegir track (CP027) | No se pudo iniciar la simulación. Revisa tu conexión. | Vuelve a iniciar la simulación. |
| Simulador: enviar respuestas (CP032) | No se pudo enviar la entrevista. Revisa tu conexión: tus respuestas siguen aquí. | Reenvía las mismas respuestas, sin volver a preguntar. |
| Asesor (CP034, CP038) | Sin conexión con el asesor. Revisa tu internet e intenta de nuevo. / No pude responder ahora. Intenta de nuevo. | Reenvía el mismo mensaje sin duplicar la burbuja. |
| Escanear (CP019) | No se pudo completar el análisis. Revisa tu conexión: tu foto no se envió. | Reenvía los puntajes ya calculados, sin repetir la foto. |
| Perfil (CP010, CP012) | No se pudo guardar el perfil. Tus cambios siguen en pantalla. | Vuelve a guardar lo escrito. |

El título "Sin conexión" solo aparece cuando falla la red. Si el servidor responde con un error, se muestra el mensaje sin ese título.

Archivos: `lib/core/widgets/connection_banner.dart` (componente reutilizable) y las pantallas `interview_selection_screen.dart`, `interview_session_screen.dart`, `chat_screen.dart`, `scan_screen.dart` y `profile_screen.dart`.

**Cómo verificarlo.**

1. Activar el modo avión y provocar cada error de la tabla.
2. Esperar más de 10 s y comprobar que el aviso sigue visible.
3. Desactivar el modo avión y tocar "Reintentar". La acción se completa y el aviso desaparece.

## Pruebas automatizadas

| Conjunto | Resultado |
|---|---|
| Backend | 31 tests, incluidos los nuevos de H02 y H03. |
| App (Flutter) | 52 tests, incluidos los nuevos de H01 y H04. |
| E2E de la API | 32 de 32. |

# CCA-F ARCADE 👾

Juego arcade en Flutter para practicar el examen **Claude Certified Architect – Foundations (CCA-F)** de Anthropic.

## Cómo correrlo

**Opción rápida (sin instalar nada):** abre https://dartpad.dev, pega el contenido
de `lib/main.dart` y presiona Run. Funciona incluso desde el celular.

**Con Flutter instalado:**
```bash
flutter create . --platforms=android,ios,web   # genera los archivos de plataforma
flutter run                                     # o: flutter run -d chrome
```

## Cómo se juega
- 5 niveles = los 5 dominios del examen (Arquitectura Agéntica, Claude Code, Tools y MCP, Prompts y Salida Estructurada, Gestión de Contexto).
- 3 vidas por misión. Fallar o quedarte sin tiempo cuesta una vida.
- Racha de aciertos = multiplicador de puntos hasta x5, más bonus por velocidad.
- 👾 JEFE FINAL: 12 preguntas mezcladas de todos los dominios con solo 15 s cada una — el simulacro del examen real.
- Cada respuesta trae explicación, y al final ves un repaso de todo lo que fallaste.
- Aprobado = ≥72% (igual que los 720/1000 del examen real).

45 preguntas en español basadas en el blueprint oficial del CCA-F.

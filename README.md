# Noticias Seguras (Flutter + NewsAPI)

App Flutter que consume **NewsAPI** con **secretos vía ENVied**, **HTTPS**, **timeout (8s)**, **retry exponencial**, **cache defensiva** y **sanitización** (OWASP).  
Estados de UI: **cargando / éxito / vacío / error**. Soporta **país (ISO-2)**, **búsqueda** y **categoría**.

---

## Requisitos
- Flutter estable + Android SDK (emulador) o dispositivo físico  
- API key válida de NewsAPI: https://newsapi.org (32 chars hex, no `pub_...`)  
- (Opcional) Postman o `curl`

---

## Instalación y secretos (ENVied)
1. Crea `.env` en la **raíz**:
   ```
   NEWS_API_KEY=TU_KEY_AQUI
   ```
   Crea también `.env.example` **sin** la clave real.
2. Genera el código de ENVied:
   ```bash
   flutter pub get
   dart run build_runner build --delete-conflicting-outputs
   ```
3. Verifica `.gitignore`:
   ```
   .env
   .env.*
   *.g.dart
   lib/env.g.dart
   ```

---

## Ejecutar
```bash
flutter devices
flutter run -d <id>
```
> **Release Android**: añade en `android/app/src/main/AndroidManifest.xml`  
> `<uses-permission android:name="android.permission.INTERNET"/>`

---

## Uso
- **País**: `mx`, `us`, `gb`…  
- **Búsqueda** (opcional): “tecnología”, “fútbol”…  
- **Categoría** (opcional): `general`, `business`, `entertainment`, `health`, `science`, `sports`, `technology`  
- Pulsa **Cargar**

### Comportamiento de datos
- Llama a `GET /v2/top-headlines`  
- Si no hay resultados (p. ej. `mx` sin query), **fallback** a `GET /v2/everything` (`language=es`, `sortBy=publishedAt`):  
  - Con búsqueda: usa esa consulta  
  - Sin búsqueda: usa “México” (para no dejar vacío en MX)  
- **Retry** (3 intentos) ante timeout/socket; **timeout** 8s; **cache** 5 min (top sin filtros)

---

## Verificar tu API key
- Navegador:
  ```
  https://newsapi.org/v2/top-headlines?country=us&pageSize=5&apiKey=TU_KEY
  ```
- o con header:
  ```bash
  curl -H "X-Api-Key: TU_KEY" "https://newsapi.org/v2/top-headlines?country=us&pageSize=5"
  ```
Esperado: `status=ok`. Si `apiKeyInvalid` → revisa key/activación.

---

## Troubleshooting rápido
- `apiKeyInvalid`: key mal/no activada  
- `429`: espera y reduce frecuencia  
- MX sin resultados: usa **búsqueda** o cambia a `us/gb`  
- Limpieza de caches Gradle/Kotlin (Windows):
  ```bash
  flutter clean
  rm -r .dart_tool build
  cd android; ./gradlew --stop; rm -r .gradle build app/build; cd ..
  flutter pub get
  dart run build_runner build --delete-conflicting-outputs
  ```

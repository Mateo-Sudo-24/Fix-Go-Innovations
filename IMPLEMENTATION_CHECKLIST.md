# 🎯 Checklist de Implementación: Vercel → Netlify Migration

**Estado General:** ✅ CÓDIGO FLUTTER 100% LISTO  
**Próximo Paso:** Configurar archivos en Netlify

---

## ✅ Fase 1: Actualización del Código Flutter (COMPLETADA)

- [x] **AndroidManifest.xml**
  - Host cambiado de `vercel-deeplink.vercel.app` a `deep-links-gofix.netlify.app`
  - Paths `/reset-password` y `/confirm-email` configurados
  - `autoVerify=\"true\"` habilitado
  - Custom scheme `fixgo://` mantenido como fallback

- [x] **auth_service.dart - Método register()**
  - ✅ `signUp()` ahora redirige a `https://deep-links-gofix.netlify.app/confirm-email`
  - ✅ Usando `emailRedirectTo` correctamente
  - ✅ Sin errores de compilación

- [x] **auth_service.dart - Método resendConfirmationEmail()**
  - ✅ `signUp()` ahora redirige a `https://deep-links-gofix.netlify.app/confirm-email`
  - ✅ Parámetro correcto para Supabase 2.5.6
  - ✅ Sin errores de compilación

- [x] **auth_service.dart - Método resetPassword()**
  - ✅ `resetPasswordForEmail()` con `redirectTo` a Netlify
  - ✅ Parámetro correcto: `redirectTo: 'https://deep-links-gofix.netlify.app/reset-password'`
  - ✅ Sin errores de compilación

- [x] **main.dart - GoRouter Routes**
  - ✅ Comentarios actualizados para `/reset-password`
  - ✅ Comentarios actualizados para `/confirm-email`
  - ✅ Rutas mantienen funcionalidad de extracción de tokens
  - ✅ Sin errores de compilación

---

## ⏳ Fase 2: Configuración de Netlify (PENDIENTE - PRÓXIMOS PASOS)

### 📁 Paso 1: Crear estructura de carpetas

- [ ] **Crear carpeta:** `reset-password/`
  - [ ] Copiar archivo HTML proporcionado en `NETLIFY_HTML_FILES.md`
  - [ ] Guardar como `reset-password/index.html`
  - [ ] Verificar que contiene el script de deep link

- [ ] **Crear carpeta:** `confirm-email/`
  - [ ] Copiar archivo HTML proporcionado en `NETLIFY_HTML_FILES.md`
  - [ ] Guardar como `confirm-email/index.html`
  - [ ] Verificar que contiene el script de deep link

- [ ] **Crear carpeta:** `.well-known/`
  - [ ] Crear archivo `assetlinks.json`
  - [ ] Ver instrucciones abajo para obtener SHA256

### 🔐 Paso 2: Obtener SHA256 de tu keystore

**Para desarrollo (debug):**
```bash
keytool -list -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android \
  -keypass android
```

**Para producción (release):**
```bash
keytool -list -v -keystore path/to/your/keystore.jks \
  -alias your-alias \
  -storepass your-password \
  -keypass your-keypass
```

Buscar línea: `SHA256: XX:XX:XX:...`

- [ ] Obtener SHA256
- [ ] Copiar valor exactamente (con los `:`)
- [ ] Guardar en un texto temporal

### 📝 Paso 3: Crear assetlinks.json

Guardar en `.well-known/assetlinks.json`:

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.fixgoinnovations",
      "sha256_cert_fingerprints": [
        "PEGA_TU_SHA256_AQUI"
      ]
    }
  }
]
```

- [ ] Reemplazar `PEGA_TU_SHA256_AQUI` con tu SHA256 real
- [ ] Mantener los `:` del SHA256
- [ ] Verificar JSON es válido (usar [jsonlint.com](https://jsonlint.com))

### 📄 Paso 4: Crear _redirects

Guardar en la raíz: `_redirects`

```
/well-known/* /.well-known/:splat 200!

[[headers]]
  for = "/*"
  [headers.values]
    X-Content-Type-Options = "nosniff"
    X-Frame-Options = "SAMEORIGIN"
    X-XSS-Protection = "1; mode=block"
    Referrer-Policy = "strict-origin-when-cross-origin"

[[headers]]
  for = "/.well-known/assetlinks.json"
  [headers.values]
    Content-Type = "application/json"
    Access-Control-Allow-Origin = "*"
    Cache-Control = "no-cache"

[[headers]]
  for = "/reset-password/index.html"
  [headers.values]
    Cache-Control = "no-cache, no-store, must-revalidate"

[[headers]]
  for = "/confirm-email/index.html"
  [headers.values]
    Cache-Control = "no-cache, no-store, must-revalidate"
```

- [ ] Crear archivo `_redirects` en raíz
- [ ] Pegar contenido exacto de arriba
- [ ] SIN extensión .txt (es solo `_redirects`)
- [ ] NO está incluido en .gitignore

### 🚀 Paso 5: Desplegar en Netlify

**Opción A: Git (Recomendado)**
```bash
git add reset-password/index.html \
        confirm-email/index.html \
        .well-known/assetlinks.json \
        _redirects

git commit -m "feat: add Netlify deep link configuration"
git push
```
- [ ] Archivos agregados a git
- [ ] Commit realizado
- [ ] Push completado
- [ ] Netlify detecta cambios y despliega automáticamente

**Opción B: Netlify UI**
- [ ] Ir a [app.netlify.com](https://app.netlify.com)
- [ ] Ir a tu sitio
- [ ] Drag & drop de la carpeta con archivos
- [ ] O usar **Deploys** → **Deploy manually**

**Opción C: Netlify CLI**
```bash
npm install -g netlify-cli
netlify login
netlify deploy --prod --dir=./
```
- [ ] CLI instalado
- [ ] Login completado
- [ ] Deploy en producción realizado

---

## 🧪 Fase 3: Verificación y Testing (DESPUÉS DE DESPLEGAR)

### ✅ Verificaciones Inmediatas

- [ ] **assetlinks.json es accesible**
  ```bash
  curl -I https://deep-links-gofix.netlify.app/.well-known/assetlinks.json
  # Esperado: HTTP/2 200
  # Esperado: Content-Type: application/json
  ```

- [ ] **reset-password es accesible**
  ```bash
  curl -I https://deep-links-gofix.netlify.app/reset-password
  # Esperado: HTTP/2 200
  ```

- [ ] **confirm-email es accesible**
  ```bash
  curl -I https://deep-links-gofix.netlify.app/confirm-email
  # Esperado: HTTP/2 200
  ```

- [ ] **assetlinks.json contiene JSON válido**
  ```bash
  curl https://deep-links-gofix.netlify.app/.well-known/assetlinks.json | jq .
  # Esperado: JSON válido sin errores
  ```

### 📱 Testing en Emulador Android

- [ ] Limpiar cache de app
  ```bash
  adb shell pm clear com.fixgoinnovations
  ```

- [ ] Probar deep link de reset
  ```bash
  adb shell am start -a android.intent.action.VIEW \
    -d "https://deep-links-gofix.netlify.app/reset-password?token=test123&type=recovery" \
    com.fixgoinnovations
  ```
  - [ ] App abre automáticamente
  - [ ] Sin selector de navegador
  - [ ] Muestra ResetPasswordScreen
  - [ ] Token se extrae correctamente

- [ ] Probar deep link de confirmación
  ```bash
  adb shell am start -a android.intent.action.VIEW \
    -d "https://deep-links-gofix.netlify.app/confirm-email?token=test456&type=signup" \
    com.fixgoinnovations
  ```
  - [ ] App abre automáticamente
  - [ ] Sin selector de navegador
  - [ ] Muestra EmailVerificationScreen
  - [ ] Token se extrae correctamente

- [ ] Ver logs de Android
  ```bash
  adb logcat | grep -E "digital_asset_links|Intent|AuthException"
  ```
  - [ ] Ver logs sin errores
  - [ ] Confirmar App Links verificado

### 👤 Testing con Usuario Real (Play Store)

- [ ] **Crear usuario de prueba**
  - [ ] Email único (ej: test-migration-20260128@gmail.com)
  - [ ] Registrarse en app

- [ ] **Verificar email de confirmación**
  - [ ] Recibir email
  - [ ] Email contiene enlace con nuevo dominio `deep-links-gofix.netlify.app`
  - [ ] Hacer click en enlace

- [ ] **Verificar app abre automáticamente**
  - [ ] Aparece EmailVerificationScreen
  - [ ] Sin popup de selector de navegador
  - [ ] Token se valida correctamente
  - [ ] Redirige a LoginScreen automáticamente

- [ ] **Probar reset de contraseña**
  - [ ] Login con usuario de prueba
  - [ ] Click en \"¿Olvidaste contraseña?\"
  - [ ] Ingresa email
  - [ ] Recibir email de reset
  - [ ] Email contiene enlace `deep-links-gofix.netlify.app/reset-password`
  - [ ] Hacer click en enlace
  - [ ] ResetPasswordScreen abre automáticamente
  - [ ] Cambiar contraseña exitosamente
  - [ ] Poder hacer login con nueva contraseña

---

## 🐛 Troubleshooting

### Problema: assetlinks.json no se encuentra

**Síntomas:** 
```
curl: (7) Failed to connect
```

**Soluciones en orden:**
- [ ] Verificar que el archivo existe: `.well-known/assetlinks.json`
- [ ] Verificar que `_redirects` contiene: `/well-known/* /.well-known/:splat 200!`
- [ ] Hacer nuevo deploy: `git push` o deploy en Netlify UI
- [ ] Esperar 2-3 minutos para que Netlify procese
- [ ] Limpiar cache del navegador (Ctrl+Shift+Del)
- [ ] Probar con curl sin cache: `curl -H \"Cache-Control: no-cache\" https://...`

### Problema: Content-Type no es application/json

**Síntomas:**
```
HTTP/2 200
Content-Type: text/html
```

**Soluciones:**
- [ ] En `_redirects`, agregar headers:
  ```
  [[headers]]
    for = "/.well-known/assetlinks.json"
    [headers.values]
      Content-Type = "application/json"
  ```
- [ ] O crear `netlify.toml` con configuración explícita
- [ ] Hacer nuevo deploy
- [ ] Esperar 5 minutos

### Problema: App Links no verificado en Android

**Síntomas:**
```
adb logcat | grep digital_asset_links
# No aparece nada o aparece error
```

**Soluciones en orden:**
- [ ] Verificar SHA256 es **exacto** (con los `:`)
- [ ] Verificar que `assetlinks.json` es válido JSON (usar [jsonlint.com](https://jsonlint.com))
- [ ] Limpiar cache de app: `adb shell pm clear com.fixgoinnovations`
- [ ] Desinstalar app: `adb uninstall com.fixgoinnovations`
- [ ] Reinstalar app: `flutter run -r`
- [ ] Esperar 24-48 horas (Android cachea en el servidor)
- [ ] Probar con diferente dispositivo/emulador

### Problema: Los deep links no abren la app

**Síntomas:**
```
Se abre navegador en lugar de app
```

**Soluciones:**
- [ ] Verificar que app está instalada: `adb shell pm list packages | grep fixgoinnovations`
- [ ] Reinstalar app: `flutter clean && flutter run`
- [ ] Limpiar cache: `adb shell pm clear com.fixgoinnovations`
- [ ] Verificar AndroidManifest.xml tiene `autoVerify=\"true\"`
- [ ] Verificar GoRouter tiene rutas `/reset-password` y `/confirm-email`
- [ ] Esperar 24-48 horas para que Android cachee el archivo

---

## 📊 Matriz de Responsabilidades

| Tarea | Hecho por | Estado |
|-------|-----------|--------|
| Actualizar código Flutter | Copilot | ✅ 100% |
| Crear archivos HTML | TÚ | ⏳ Pendiente |
| Obtener SHA256 | TÚ | ⏳ Pendiente |
| Crear assetlinks.json | TÚ | ⏳ Pendiente |
| Crear _redirects | TÚ | ⏳ Pendiente |
| Desplegar en Netlify | TÚ | ⏳ Pendiente |
| Testing en emulador | TÚ | ⏳ Pendiente |
| Testing con usuario real | TÚ | ⏳ Pendiente |

---

## 🎓 Recursos de Referencia

Abiertos en proyecto:
- ✅ `NETLIFY_DEEPLINKS_SETUP.md` - Guía completa
- ✅ `NETLIFY_HTML_FILES.md` - Archivos HTML listos
- ✅ `NETLIFY_REDIRECTS.md` - Configuración _redirects
- ✅ `QUICK_MIGRATION_SUMMARY.md` - Resumen rápido
- ✅ `MIGRATION_COMPLETE.md` - Resumen general

Externos:
- [Netlify Docs](https://docs.netlify.com)
- [Android App Links](https://developer.android.com/training/app-links)
- [Supabase Auth](https://supabase.com/docs/guides/auth)
- [Flutter Deep Links](https://flutter.dev/docs/development/ui/navigation/deep-linking)

---

## 🏁 Resumen Estado Actual

```
📊 COMPLETITUD GENERAL: 25% (Fase 1/3)

Fase 1: Código Flutter          ████████████████████ 100% ✅
Fase 2: Config Netlify          ░░░░░░░░░░░░░░░░░░░░   0% ⏳
Fase 3: Testing & Verificación  ░░░░░░░░░░░░░░░░░░░░   0% ⏳

BLOQUEADOR: Espera a que completes Fase 2 en Netlify
PRÓXIMO: Seguir pasos en Fase 2 de este checklist
```

---

## ✍️ Notas y Progreso

```
[Tu espacio para anotar progreso]

Iniciado: _________________
Fase 2 completada: _________________
Primer test: _________________
Producción: _________________

Notas:
- ________________________________________________________________
- ________________________________________________________________
- ________________________________________________________________
```

---

**Última Actualización:** 28 de Enero, 2026  
**Creado por:** GitHub Copilot  
**Próxima Acción:** Sigue los pasos de Fase 2

🚀 **¡Listo para continuar!**

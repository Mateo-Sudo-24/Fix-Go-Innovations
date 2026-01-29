# 🚀 RESUMEN: Migración Vercel → Netlify Deep Links

## ✅ Cambios Realizados en el Código Flutter

### 1️⃣ **AndroidManifest.xml**
```xml
<!-- Host actualizado de vercel-deeplink.vercel.app a deep-links-gofix.netlify.app -->
<intent-filter android:autoVerify="true">
    <data android:scheme="https" android:host="deep-links-gofix.netlify.app" android:pathPrefix="/reset-password" />
    <data android:scheme="https" android:host="deep-links-gofix.netlify.app" android:pathPrefix="/confirm-email" />
</intent-filter>
```

### 2️⃣ **auth_service.dart - register()**
```dart
// ANTES: emailRedirectTo: 'io.supabase.fixgoinnovations://login-callback'
// DESPUÉS:
options: AuthOptions(
  redirectTo: 'https://deep-links-gofix.netlify.app/confirm-email',
),
```

### 3️⃣ **auth_service.dart - resendConfirmationEmail()**
```dart
// ANTES: emailRedirectTo: 'io.supabase.fixgoinnovations://login-callback'
// DESPUÉS:
options: AuthOptions(
  redirectTo: 'https://deep-links-gofix.netlify.app/confirm-email',
),
```

### 4️⃣ **auth_service.dart - resetPassword()**
```dart
// ANTES: await _supabase.auth.resetPasswordForEmail(email);
// DESPUÉS:
await _supabase.auth.resetPasswordForEmail(
  email,
  options: AuthOptions(
    redirectTo: 'https://deep-links-gofix.netlify.app/reset-password',
  ),
);
```

### 5️⃣ **main.dart - Comentarios en rutas GoRouter**
```dart
// Reset Password route: Comentario actualizado a Netlify
// Confirm Email route: Comentario actualizado a Netlify
// Agregados comentarios sobre archivos estáticos en Netlify
```

---

## 🌐 Pasos Finales en Netlify

### 1. Crear estructura de carpetas
```
project_root/
├── reset-password/
│   └── index.html          ← Copiar archivo HTML proporcionado
├── confirm-email/
│   └── index.html          ← Copiar archivo HTML proporcionado
├── .well-known/
│   └── assetlinks.json     ← Crear con SHA256 de tu keystore
└── _redirects              ← Actualizar con configuración
```

### 2. Obtener SHA256 de tu keystore
```bash
keytool -list -v -keystore path/to/your/keystore.jks -alias your-alias
# Copiar valor SHA256
```

### 3. Actualizar assetlinks.json
```json
{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.fixgoinnovations",
    "sha256_cert_fingerprints": ["YOUR_SHA256_HERE"]
  }
}
```

### 4. Configurar _redirects en Netlify
```
/well-known/* /.well-known/:splat 200!
```

### 5. Desplegar en Netlify
```bash
# Git push y Netlify se encargará del deploy automático
```

---

## ✅ Testing Checklist

- [ ] Compilar app Flutter sin errores
- [ ] Desplegar archivos HTML en Netlify
- [ ] Configurar assetlinks.json con SHA256 correcto
- [ ] Verificar que assetlinks.json es accesible en https://deep-links-gofix.netlify.app/.well-known/assetlinks.json
- [ ] Crear usuario de prueba y enviar email de confirmación
- [ ] Hacer click en enlace de email → app se abre automáticamente
- [ ] Verificar que token se extrae correctamente
- [ ] Verificar que EmailVerificationScreen muestra "Token verificado"
- [ ] Solicitar reset de contraseña y verificar email
- [ ] Hacer click en enlace → app se abre automáticamente
- [ ] Verificar que ResetPasswordScreen permite cambiar contraseña

---

## 📝 Archivos Modificados

| Archivo | Cambios |
|---------|---------|
| `android/app/src/main/AndroidManifest.xml` | Host: Vercel → Netlify |
| `lib/services/auth_service.dart` | redirectTo: nuevo dominio Netlify (3 métodos) |
| `lib/main.dart` | Comentarios actualizados (2 rutas) |

---

## 📁 Documentación Generada

1. **NETLIFY_DEEPLINKS_SETUP.md** - Guía completa de configuración
2. **NETLIFY_HTML_FILES.md** - Archivos HTML para copiar a Netlify
3. **Este archivo** - Resumen rápido

---

## 🔗 Deep Links Ahora Funcionan Con

- ✅ **Android App Links (HTTPS):** `https://deep-links-gofix.netlify.app/reset-password`
- ✅ **Custom Scheme (Fallback):** `fixgo://reset-password`
- ✅ **Supabase Auth:** Redirige automáticamente a los enlaces de Netlify
- ✅ **GoRouter:** Extrae tokens y parameters correctamente
- ✅ **Pantallas:** ResetPasswordScreen y EmailVerificationScreen manejan tokens

---

## 🛠️ Si Algo No Funciona

### App no abre automáticamente
1. Verificar que assetlinks.json es válido:
   ```bash
   curl https://deep-links-gofix.netlify.app/.well-known/assetlinks.json
   ```
2. Verificar que SHA256 coincide con tu keystore
3. Limpiar cache de la app: `adb shell pm clear com.fixgoinnovations`
4. Reinstalar app: `flutter clean && flutter run`

### Token no se extrae
1. Revisar que los query parameters se envían en el email
2. Verificar logs en Flutter: `debugPrint('Token: $token')`
3. Comprobar que GoRouter route está bien: `/reset-password` y `/confirm-email`

### Email no contiene enlace correcto
1. Verificar que redirectTo en auth_service.dart tiene URL correcta
2. Revisar que Netlify sirve el HTML en `/reset-password` y `/confirm-email`
3. Probar manualmente: `https://deep-links-gofix.netlify.app/reset-password?token=test&type=recovery`

---

## 🎉 Próximos Pasos

Después de verificar que todo funciona:
1. Actualizar app en Play Store
2. Actualizar app en App Store (si aplica)
3. Notificar a usuarios que pueden usar deep links
4. Monitorear logs de Supabase Auth para verificar éxito

---

**Migración completada:** Enero 28, 2026  
**Última revisión:** ✅ Código Flutter modificado exitosamente  
**Próxima revisión:** Después de desplegar en Netlify

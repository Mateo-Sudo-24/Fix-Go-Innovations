# 🌐 Migración de Deep Links: Vercel → Netlify

**Fecha:** Enero 28, 2026  
**Dominio Anterior:** `vercel-deeplink.vercel.app`  
**Nuevo Dominio:** `https://deep-links-gofix.netlify.app`

---

## 📋 Resumen de Cambios

Se han actualizado todos los archivos del proyecto Flutter para que funcionen con el nuevo dominio de Netlify y App Links (HTTPS) verificado automáticamente por Android.

### ✅ Archivos Modificados

#### 1. **android/app/src/main/AndroidManifest.xml**
- ✅ Actualizado host en intent-filter HTTPS
- ✅ Cambiado de `vercel-deeplink.vercel.app` a `deep-links-gofix.netlify.app`
- ✅ Mantiene `autoVerify="true"` (requiere assetlinks.json en Netlify)
- ✅ Ruta: `/reset-password` y `/confirm-email`
- ✅ Custom scheme `fixgo://` se mantiene como fallback

```xml
<!-- HTTPS Deep Links con App Links (Netlify) -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    
    <!-- Reset Password -->
    <data
        android:scheme="https"
        android:host="deep-links-gofix.netlify.app"
        android:pathPrefix="/reset-password" />
    
    <!-- Confirm Email -->
    <data
        android:scheme="https"
        android:host="deep-links-gofix.netlify.app"
        android:pathPrefix="/confirm-email" />
</intent-filter>
```

#### 2. **lib/services/auth_service.dart**

**Cambio 1: `register()` - SignUp para confirmación de email**
```dart
// ANTES
final AuthResponse authResponse = await _supabase.auth.signUp(
  email: user.email,
  password: password,
  emailRedirectTo: 'io.supabase.fixgoinnovations://login-callback',
);

// DESPUÉS
final AuthResponse authResponse = await _supabase.auth.signUp(
  email: user.email,
  password: password,
  options: AuthOptions(
    redirectTo: 'https://deep-links-gofix.netlify.app/confirm-email',
  ),
);
```

**Cambio 2: `resendConfirmationEmail()` - Reenvío de OTP**
```dart
// ANTES
await _supabase.auth.signUp(
  email: email,
  password: 'temporary_pass_12345',
  emailRedirectTo: 'io.supabase.fixgoinnovations://login-callback',
);

// DESPUÉS
await _supabase.auth.signUp(
  email: email,
  password: 'temporary_pass_12345',
  options: AuthOptions(
    redirectTo: 'https://deep-links-gofix.netlify.app/confirm-email',
  ),
);
```

**Cambio 3: `resetPassword()` - Reset de contraseña**
```dart
// ANTES
await _supabase.auth.resetPasswordForEmail(email);

// DESPUÉS
await _supabase.auth.resetPasswordForEmail(
  email,
  options: AuthOptions(
    redirectTo: 'https://deep-links-gofix.netlify.app/reset-password',
  ),
);
```

#### 3. **lib/main.dart**

**Actualización de comentarios en rutas GoRouter:**
- Reset Password route: Ahora documenta `https://deep-links-gofix.netlify.app/reset-password`
- Confirm Email route: Ahora documenta `https://deep-links-gofix.netlify.app/confirm-email`
- Agregado comentario sobre archivos estáticos en Netlify

```dart
// 🔗 DEEP LINK: Reset Password Route
// Handles: https://deep-links-gofix.netlify.app/reset-password?token=XXX&type=recovery
// 🌐 Netlify Config: Archivo estático en /reset-password/index.html

// 🔗 DEEP LINK: Confirm Email Route
// Handles: https://deep-links-gofix.netlify.app/confirm-email?token=XXX&type=signup
// 🌐 Netlify Config: Archivo estático en /confirm-email/index.html
```

---

## 🚀 Flujo de Funcionamiento

### 1️⃣ **Confirmación de Email (SignUp)**

```
Usuario registra → 
  ↓
Supabase envía email con enlace:
  https://deep-links-gofix.netlify.app/confirm-email?token=XXX&type=signup
  ↓
Netlify redirige a /confirm-email/index.html (archivo estático)
  ↓
Android intercepta deep link (App Links verificado)
  ↓
GoRouter reconoce /confirm-email y extrae token
  ↓
EmailVerificationScreen.initState() llama _verifyTokenWithSupabase()
  ↓
Supabase verifyOTP(token: token, type: OtpType.signup)
  ↓
Navegación a LoginScreen
```

### 2️⃣ **Reset de Contraseña**

```
Usuario hace click en "¿Olvidaste contraseña?" →
  ↓
ForgotPasswordScreen llama authService.resetPassword(email)
  ↓
Supabase envía email con enlace:
  https://deep-links-gofix.netlify.app/reset-password?token=XXX&type=recovery
  ↓
Netlify redirige a /reset-password/index.html (archivo estático)
  ↓
Android intercepta deep link (App Links verificado)
  ↓
GoRouter reconoce /reset-password y extrae token
  ↓
ResetPasswordScreen.initState() llama _verifyTokenWithSupabase()
  ↓
Supabase verifyOTP(token: token, type: OtpType.recovery)
  ↓
Usuario ingresa nueva contraseña y confirma
```

---

## 🔧 Configuración de Netlify Requerida

### Archivos Estáticos Necesarios

1. **`/reset-password/index.html`** - Archivo HTML estático que redirige a la app
2. **`/confirm-email/index.html`** - Archivo HTML estático que redirige a la app
3. **`/.well-known/assetlinks.json`** - Para verificación App Links de Android

### Archivo: `_redirects` (Netlify)

```
# Redirigir /.well-known/assetlinks.json
/well-known/* /.well-known/:splat 200!

# O simplemente servir el archivo
/.well-known/assetlinks.json /well-known/assetlinks.json 200! Content-Type: application/json
```

### Ejemplo: `/reset-password/index.html`

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Restablecer Contraseña</title>
    <script>
        // Capturar los query parameters y pasarlos a la app
        const params = new URLSearchParams(window.location.search);
        const token = params.get('token') || params.get('access_token');
        const type = params.get('type') || 'recovery';
        
        // Redirigir a la app con deep link
        // Opción 1: Usar App Links (Android 6+)
        const deepLink = `https://deep-links-gofix.netlify.app/reset-password?token=${token}&type=${type}`;
        
        // Opción 2: Custom scheme como fallback
        const fallbackScheme = `fixgo://reset-password?token=${token}&type=${type}`;
        
        // Intent Android (más confiable)
        const intent = `intent://${deepLink.replace('https://', '')}#Intent;package=com.fixgoinnovations;scheme=https;end`;
        
        // Redirigir después de 500ms
        setTimeout(() => {
            window.location.href = deepLink;
        }, 500);
    </script>
</head>
<body>
    <p>Abriendo Fix&Go...</p>
</body>
</html>
```

### Ejemplo: `/confirm-email/index.html`

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Confirmar Email</title>
    <script>
        const params = new URLSearchParams(window.location.search);
        const token = params.get('token') || params.get('access_token');
        const type = params.get('type') || 'signup';
        
        const deepLink = `https://deep-links-gofix.netlify.app/confirm-email?token=${token}&type=${type}`;
        
        setTimeout(() => {
            window.location.href = deepLink;
        }, 500);
    </script>
</head>
<body>
    <p>Confirmando tu email...</p>
</body>
</html>
```

---

## 🔐 Verificación de App Links

### Generar Certificado SHA-256 (Android)

```bash
# Obtener el certificado SHA-256 de la app
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Salida esperada:
# SHA256: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

### Contenido de `/.well-known/assetlinks.json`

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.fixgoinnovations",
      "sha256_cert_fingerprints": ["XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX"]
    }
  }
]
```

### Verificar Validez de App Links

```bash
# Usar la herramienta de verificación de Android
adb shell am start -a android.intent.action.VIEW \
  -d "https://deep-links-gofix.netlify.app/reset-password?token=test&type=recovery" \
  com.fixgoinnovations

# Revisar logs de verificación
adb logcat | grep "digital_asset_links"
```

---

## 📱 Pantallas Involucradas

### 1. **ResetPasswordScreen** (`lib/screens/auth/reset_password_screen.dart`)
- ✅ Recibe `token`, `type`, y bandera `isDeepLink`
- ✅ En `initState()`: Si `isDeepLink=true`, llama `_verifyTokenWithSupabase()`
- ✅ `verifyOTP(token: token, type: OtpType.recovery)` verifica con Supabase
- ✅ Si es válido: Usuario puede ingresar nueva contraseña
- ✅ Si es inválido: Muestra error "Token inválido o expirado"

### 2. **EmailVerificationScreen** (`lib/screens/auth/email_verification_screen.dart`)
- ✅ Recibe `token`, `type`, y bandera `isDeepLink`
- ✅ En `initState()`: Si `isDeepLink=true`, llama `_verifyTokenWithSupabase()`
- ✅ `verifyOTP(token: token, type: OtpType.signup)` verifica con Supabase
- ✅ Si es válido: Redirige automáticamente a LoginScreen
- ✅ Si es inválido: Muestra opción para reenviar email

---

## 🧪 Testing Checklist

### ✅ Pruebas Locales (Emulador Android)

```dart
// En main.dart, puedes simular deep links con:
GoRouter router = GoRouter(
  initialLocation: '/reset-password?token=test_token&type=recovery',
  // ... resto de config
);
```

```bash
# O desde terminal del emulador
adb shell am start -a android.intent.action.VIEW \
  -d "https://deep-links-gofix.netlify.app/reset-password?token=test&type=recovery" \
  com.fixgoinnovations
```

### ✅ Pruebas en Productor

1. **Sign Up Flow:**
   - [ ] Usuario se registra en app
   - [ ] Recibe email con enlace de confirmación
   - [ ] Hace click en enlace
   - [ ] App se abre automáticamente en EmailVerificationScreen
   - [ ] Verifica token y redirige a Login

2. **Reset Password Flow:**
   - [ ] Usuario hace click en "¿Olvidaste contraseña?"
   - [ ] Ingresa email y envía formulario
   - [ ] Recibe email con enlace de reset
   - [ ] Hace click en enlace
   - [ ] App se abre automáticamente en ResetPasswordScreen
   - [ ] Verifica token y permite cambiar contraseña
   - [ ] Contraseña se actualiza correctamente

3. **Verificación de App Links:**
   - [ ] Android reconoce el dominio como App Links
   - [ ] No muestra selector de navegador
   - [ ] Deep link se maneja automáticamente en la app

---

## 🛠️ Debugging

### Logs Útiles en Flutter

```dart
// En GoRouter:
debugPrint('🔗 Deep Link URI: ${state.uri}');
debugPrint('🔐 Token: $token, Type: $type');

// En pantallas:
debugPrint('🔍 Verificando token: ${widget.token}');
debugPrint('✅ Token verificado exitosamente');
debugPrint('❌ Error verificando token: $e');
```

### Logs de Android

```bash
# Ver logs de verificación de App Links
adb logcat | grep -i "digital_asset_links\|app_links\|intent_filter"

# Ver intents capturados
adb logcat | grep "Intent"

# Ver errores de Supabase Auth
adb logcat | grep "AuthException"
```

---

## 📝 Resumen Final

| Componente | Antes | Después |
|-----------|-------|---------|
| Host HTTPS | `vercel-deeplink.vercel.app` | `deep-links-gofix.netlify.app` |
| Método redirectTo | `emailRedirectTo` (deprecado) | `options: AuthOptions(redirectTo:)` |
| App Links | No configurado | Configurado con autoVerify=true |
| Custom Scheme | `fixgo://` | `fixgo://` (se mantiene) |
| Archivos Netlify | `/` | `/reset-password/index.html`, `/confirm-email/index.html`, `/.well-known/assetlinks.json` |

---

## 🔗 Referencias Útiles

- [Android App Links Documentation](https://developer.android.com/training/app-links)
- [Supabase Auth Deep Links](https://supabase.com/docs/guides/auth/deep-linking)
- [Netlify Redirects](https://docs.netlify.com/routing/redirects/)
- [GoRouter Documentation](https://pub.dev/packages/go_router)

---

**Última Actualización:** Enero 28, 2026  
**Creado por:** GitHub Copilot

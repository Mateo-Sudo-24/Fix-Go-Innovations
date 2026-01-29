# 📁 Archivos HTML para Netlify Deep Links

Este documento contiene los archivos HTML que debes crear en tu proyecto de Netlify para manejar los deep links de reset de contraseña y confirmación de email.

---

## 🔧 Estructura de Carpetas Esperada en Netlify

```
project_root/
├── index.html                      (Página principal)
├── _redirects                      (Configuración de redirecciones)
├── reset-password/
│   └── index.html                  (Maneja: /reset-password?token=XXX&type=recovery)
├── confirm-email/
│   └── index.html                  (Maneja: /confirm-email?token=XXX&type=signup)
└── .well-known/
    └── assetlinks.json             (Verificación App Links para Android)
```

---

## 📄 Archivo 1: `/reset-password/index.html`

**Ubicación:** `project_root/reset-password/index.html`

```html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Restablecer Contraseña - Fix&Go</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            color: white;
        }
        
        .container {
            text-align: center;
            background: rgba(0, 0, 0, 0.3);
            padding: 40px;
            border-radius: 16px;
            backdrop-filter: blur(10px);
        }
        
        .icon {
            font-size: 64px;
            margin-bottom: 20px;
            animation: spin 2s linear infinite;
        }
        
        @keyframes spin {
            from {
                transform: rotate(0deg);
            }
            to {
                transform: rotate(360deg);
            }
        }
        
        h1 {
            font-size: 24px;
            margin-bottom: 12px;
            font-weight: 600;
        }
        
        p {
            font-size: 16px;
            opacity: 0.9;
            margin-bottom: 20px;
        }
        
        .details {
            font-size: 13px;
            opacity: 0.7;
            margin-top: 20px;
            text-align: left;
            background: rgba(0, 0, 0, 0.2);
            padding: 12px;
            border-radius: 8px;
            max-width: 300px;
            margin-left: auto;
            margin-right: auto;
        }
        
        code {
            background: rgba(0, 0, 0, 0.3);
            padding: 2px 6px;
            border-radius: 4px;
            font-family: 'Monaco', 'Courier New', monospace;
            font-size: 12px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="icon">🔐</div>
        <h1>Abriendo Fix&Go...</h1>
        <p>Estamos procesando tu solicitud de cambio de contraseña.</p>
        
        <div class="details">
            <p><strong>¿Qué está pasando?</strong></p>
            <p>Se está abriendo automáticamente la aplicación Fix&Go con tu token de verificación.</p>
            <p>Si la app no se abre en 5 segundos, asegúrate de tener instalada la última versión.</p>
        </div>
    </div>

    <script>
        // ==================== CAPTURAR PARÁMETROS ====================
        const params = new URLSearchParams(window.location.search);
        const token = params.get('token') || params.get('access_token') || '';
        const type = params.get('type') || 'recovery';
        
        console.log('🔗 Reset Password Deep Link Handler');
        console.log('Token:', token);
        console.log('Type:', type);

        // ==================== CREAR DEEP LINKS ====================
        // Opción 1: App Links (HTTPS) - Recomendado para Android 6+
        const httpsDeepLink = `https://deep-links-gofix.netlify.app/reset-password?token=${encodeURIComponent(token)}&type=${encodeURIComponent(type)}`;
        
        // Opción 2: Custom Scheme - Fallback para versiones antiguas
        const customSchemeDeepLink = `fixgo://reset-password?token=${encodeURIComponent(token)}&type=${encodeURIComponent(type)}`;
        
        // Opción 3: Intent URI para Android (más confiable)
        const androidIntent = `intent://reset-password?token=${encodeURIComponent(token)}&type=${encodeURIComponent(type)}#Intent;package=com.fixgoinnovations;scheme=https;launchFlags=0x10000000;end`;

        // ==================== INTENTAR ABRIR APP ====================
        function openApp() {
            console.log('📱 Intentando abrir app...');
            
            // Detectar plataforma
            const userAgent = navigator.userAgent.toLowerCase();
            const isAndroid = userAgent.includes('android');
            const isIOS = userAgent.includes('iphone') || userAgent.includes('ipad');
            
            console.log('Platform:', { isAndroid, isIOS });

            if (isAndroid) {
                // Android: Probar primero con Intent, luego esquema personalizado
                console.log('🤖 Plataforma: Android');
                
                try {
                    // Intentar con App Links (HTTPS)
                    window.location.href = httpsDeepLink;
                    console.log('✅ Abriendo con App Links (HTTPS)');
                } catch (error) {
                    console.warn('❌ App Links falló, intentando custom scheme');
                    setTimeout(() => {
                        window.location.href = customSchemeDeepLink;
                    }, 1000);
                }
            } else if (isIOS) {
                // iOS: Custom scheme
                console.log('🍎 Plataforma: iOS');
                window.location.href = `fixgoinnovations://reset-password?token=${encodeURIComponent(token)}&type=${encodeURIComponent(type)}`;
            } else {
                // Web: Mostrar mensaje alternativo
                console.log('🌐 Plataforma: Web');
                document.body.innerHTML += `<p style="margin-top: 40px; font-size: 14px;">Por favor, abre esta página en tu dispositivo móvil.</p>`;
            }
        }

        // Esperar a que el DOM esté listo y luego abrir la app
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', openApp);
        } else {
            // DOM ya está listo
            setTimeout(openApp, 500);
        }

        // Si después de 5 segundos la app no se abre, mostrar instrucción alternativa
        setTimeout(() => {
            console.log('⚠️ La app no se abrió automáticamente. Mostrando alternativa.');
            
            // Crear botón alternativo
            const btn = document.createElement('button');
            btn.textContent = '👉 Toca aquí para abrir Fix&Go';
            btn.style.cssText = `
                margin-top: 30px;
                padding: 12px 24px;
                background: #667eea;
                color: white;
                border: none;
                border-radius: 8px;
                font-size: 16px;
                font-weight: 600;
                cursor: pointer;
                transition: all 0.3s ease;
            `;
            
            btn.onmouseover = () => btn.style.background = '#5568d3';
            btn.onmouseout = () => btn.style.background = '#667eea';
            
            btn.onclick = openApp;
            
            document.querySelector('.container').appendChild(btn);
        }, 5000);

        // ==================== LOGGING ====================
        window.addEventListener('beforeunload', () => {
            console.log('🚀 Navegando a deep link...');
        });

        // Capturar errores
        window.addEventListener('error', (event) => {
            console.error('❌ Error en página:', event.error);
        });
    </script>
</body>
</html>
```

---

## 📄 Archivo 2: `/confirm-email/index.html`

**Ubicación:** `project_root/confirm-email/index.html`

```html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Confirmar Email - Fix&Go</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            color: white;
        }
        
        .container {
            text-align: center;
            background: rgba(0, 0, 0, 0.3);
            padding: 40px;
            border-radius: 16px;
            backdrop-filter: blur(10px);
        }
        
        .icon {
            font-size: 64px;
            margin-bottom: 20px;
            animation: bounce 2s infinite;
        }
        
        @keyframes bounce {
            0%, 100% {
                transform: translateY(0);
            }
            50% {
                transform: translateY(-10px);
            }
        }
        
        h1 {
            font-size: 24px;
            margin-bottom: 12px;
            font-weight: 600;
        }
        
        p {
            font-size: 16px;
            opacity: 0.9;
            margin-bottom: 20px;
        }
        
        .details {
            font-size: 13px;
            opacity: 0.7;
            margin-top: 20px;
            text-align: left;
            background: rgba(0, 0, 0, 0.2);
            padding: 12px;
            border-radius: 8px;
            max-width: 300px;
            margin-left: auto;
            margin-right: auto;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="icon">📧</div>
        <h1>Confirmando tu email...</h1>
        <p>Abriendo Fix&Go para completar la verificación.</p>
        
        <div class="details">
            <p><strong>¿Qué está pasando?</strong></p>
            <p>Tu email está siendo verificado automáticamente en la aplicación Fix&Go.</p>
            <p>Serás redirigido a la pantalla de login una vez completado.</p>
        </div>
    </div>

    <script>
        // ==================== CAPTURAR PARÁMETROS ====================
        const params = new URLSearchParams(window.location.search);
        const token = params.get('token') || params.get('access_token') || '';
        const type = params.get('type') || 'signup';
        
        console.log('🔗 Confirm Email Deep Link Handler');
        console.log('Token:', token);
        console.log('Type:', type);

        // ==================== CREAR DEEP LINKS ====================
        const httpsDeepLink = `https://deep-links-gofix.netlify.app/confirm-email?token=${encodeURIComponent(token)}&type=${encodeURIComponent(type)}`;
        const customSchemeDeepLink = `fixgo://confirm-email?token=${encodeURIComponent(token)}&type=${encodeURIComponent(type)}`;

        // ==================== INTENTAR ABRIR APP ====================
        function openApp() {
            console.log('📱 Intentando abrir app...');
            
            const userAgent = navigator.userAgent.toLowerCase();
            const isAndroid = userAgent.includes('android');
            const isIOS = userAgent.includes('iphone') || userAgent.includes('ipad');
            
            console.log('Platform:', { isAndroid, isIOS });

            if (isAndroid) {
                console.log('🤖 Plataforma: Android');
                try {
                    window.location.href = httpsDeepLink;
                    console.log('✅ Abriendo con App Links (HTTPS)');
                } catch (error) {
                    console.warn('❌ App Links falló, intentando custom scheme');
                    setTimeout(() => {
                        window.location.href = customSchemeDeepLink;
                    }, 1000);
                }
            } else if (isIOS) {
                console.log('🍎 Plataforma: iOS');
                window.location.href = `fixgoinnovations://confirm-email?token=${encodeURIComponent(token)}&type=${encodeURIComponent(type)}`;
            } else {
                console.log('🌐 Plataforma: Web');
                document.body.innerHTML += `<p style="margin-top: 40px; font-size: 14px;">Por favor, abre esta página en tu dispositivo móvil.</p>`;
            }
        }

        // Ejecutar después de cargar
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', openApp);
        } else {
            setTimeout(openApp, 500);
        }

        // Fallback después de 5 segundos
        setTimeout(() => {
            console.log('⚠️ La app no se abrió automáticamente.');
            
            const btn = document.createElement('button');
            btn.textContent = '👉 Toca aquí para abrir Fix&Go';
            btn.style.cssText = `
                margin-top: 30px;
                padding: 12px 24px;
                background: #667eea;
                color: white;
                border: none;
                border-radius: 8px;
                font-size: 16px;
                font-weight: 600;
                cursor: pointer;
                transition: all 0.3s ease;
            `;
            
            btn.onmouseover = () => btn.style.background = '#5568d3';
            btn.onmouseout = () => btn.style.background = '#667eea';
            
            btn.onclick = openApp;
            
            document.querySelector('.container').appendChild(btn);
        }, 5000);
    </script>
</body>
</html>
```

---

## 📄 Archivo 3: `/_redirects`

**Ubicación:** `project_root/_redirects`

Este archivo configura cómo Netlify maneja las redirecciones y archivos estáticos.

```
# ==================== WELL-KNOWN (App Links & ACME) ====================
# Redirigir /.well-known/* a /well-known/*
/well-known/* /.well-known/:splat 200!

# ==================== DEEP LINKS ====================
# No necesitas hacer nada aquí si tienes los archivos index.html en las carpetas
# Netlify automáticamente servirá /reset-password/index.html para /reset-password
# y /confirm-email/index.html para /confirm-email

# ==================== SPA ROUTING (si lo necesitas) ====================
# Si tienes una app web SPA, descomenta esto:
# /*    /index.html   200

# ==================== HEADERS (Seguridad) ====================
# Aplicar headers de seguridad a todos los archivos
[[headers]]
  for = "/*"
  [headers.values]
    X-Content-Type-Options = "nosniff"
    X-Frame-Options = "SAMEORIGIN"
    X-XSS-Protection = "1; mode=block"
    Referrer-Policy = "strict-origin-when-cross-origin"

# Configuración especial para assetlinks.json
[[headers]]
  for = "/.well-known/assetlinks.json"
  [headers.values]
    Content-Type = "application/json"
    Access-Control-Allow-Origin = "*"
```

---

## 📄 Archivo 4: `/.well-known/assetlinks.json`

**Ubicación:** `project_root/.well-known/assetlinks.json`

Este archivo es **crucial** para que Android verifique automáticamente tu dominio como App Links.

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.fixgoinnovations",
      "sha256_cert_fingerprints": [
        "XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX"
      ]
    }
  }
]
```

### 🔑 Cómo Obtener el SHA256

```bash
# Para debug keystore (desarrollo)
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Para release keystore (producción)
keytool -list -v -keystore path/to/your/keystore.jks -alias your-alias -storepass your-password -keypass your-keypass

# Salida (busca SHA256):
# SHA256: AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99
```

Reemplaza en el JSON:
```json
"sha256_cert_fingerprints": [
  "AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99"
]
```

---

## ✅ Verificación

Después de desplegar en Netlify:

1. **Verificar assetlinks.json es accesible:**
   ```bash
   curl -I https://deep-links-gofix.netlify.app/.well-known/assetlinks.json
   # Debe devolver: Content-Type: application/json
   ```

2. **Verificar páginas de deep link:**
   ```bash
   curl -I https://deep-links-gofix.netlify.app/reset-password
   curl -I https://deep-links-gofix.netlify.app/confirm-email
   # Deben devolver: 200 OK
   ```

3. **Verificar App Links en Android:**
   ```bash
   adb shell am start -a android.intent.action.VIEW \
     -d "https://deep-links-gofix.netlify.app/reset-password?token=test&type=recovery" \
     com.fixgoinnovations
   
   # Ver logs
   adb logcat | grep "digital_asset_links"
   ```

---

## 🔗 Resumen de Flujo

```
Usuario hace click en enlace de email
    ↓
https://deep-links-gofix.netlify.app/reset-password?token=XXX&type=recovery
    ↓
Netlify sirve /reset-password/index.html
    ↓
Script captura token y type
    ↓
Crea deep link: https://deep-links-gofix.netlify.app/reset-password?token=XXX&type=recovery
    ↓
Android intercepta (App Links verificado)
    ↓
Flutter app abre con GoRouter
    ↓
ResetPasswordScreen recibe token y lo verifica con Supabase
```

---

**Última actualización:** Enero 28, 2026

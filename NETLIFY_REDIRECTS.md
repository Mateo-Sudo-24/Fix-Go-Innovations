# 🌐 Archivo _redirects para Netlify

Copia este contenido exactamente a un archivo llamado `_redirects` en la raíz de tu proyecto Netlify.

---

## 📄 Contenido de `_redirects`

```
# ==================== WELL-KNOWN (App Links & Security) ====================
# Redirigir /.well-known/* a /well-known/*
# Requerido para: assetlinks.json (Android App Links)
/well-known/* /.well-known/:splat 200!

# ==================== DEEP LINKS ====================
# Netlify automáticamente sirve /reset-password/index.html para /reset-password
# y /confirm-email/index.html para /confirm-email
# No es necesario agregar reglas aquí si tienes los archivos index.html

# ==================== HEADERS (SEGURIDAD) ====================
# Aplicar headers de seguridad a todos los archivos estáticos

[[headers]]
  for = "/*"
  [headers.values]
    # Prevenir MIME type sniffing
    X-Content-Type-Options = "nosniff"
    # Proteger contra clickjacking
    X-Frame-Options = "SAMEORIGIN"
    # Proteger contra XSS
    X-XSS-Protection = "1; mode=block"
    # Control de referrer
    Referrer-Policy = "strict-origin-when-cross-origin"

# ==================== HEADERS ESPECIALES para assetlinks.json ====================

[[headers]]
  for = "/.well-known/assetlinks.json"
  [headers.values]
    # Asegurar que se sirve como JSON
    Content-Type = "application/json"
    # Permitir acceso desde cualquier origen (Android requiere esto)
    Access-Control-Allow-Origin = "*"
    # No cachear (Android lo verifica frecuentemente)
    Cache-Control = "no-cache"

# ==================== CACHE ====================

[[headers]]
  for = "/reset-password/index.html"
  [headers.values]
    Cache-Control = "no-cache, no-store, must-revalidate"

[[headers]]
  for = "/confirm-email/index.html"
  [headers.values]
    Cache-Control = "no-cache, no-store, must-revalidate"
```

---

## 📁 Estructura de Carpetas en Netlify

Tu proyecto en Netlify debe verse así:

```
project-root/
├── _redirects                          ← Este archivo
├── index.html                          (página web principal)
├── reset-password/
│   └── index.html                      (HTML proporcionado)
├── confirm-email/
│   └── index.html                      (HTML proporcionado)
└── .well-known/
    └── assetlinks.json                 (JSON con SHA256)
```

---

## ✅ Verificación Rápida

Después de desplegar en Netlify, verifica que todo funcione:

```bash
# 1. Verificar que assetlinks.json es accesible
curl -I https://deep-links-gofix.netlify.app/.well-known/assetlinks.json
# Esperado: HTTP/2 200, Content-Type: application/json

# 2. Verificar que reset-password es accesible
curl -I https://deep-links-gofix.netlify.app/reset-password
# Esperado: HTTP/2 200

# 3. Verificar que confirm-email es accesible
curl -I https://deep-links-gofix.netlify.app/confirm-email
# Esperado: HTTP/2 200

# 4. Verificar contenido de assetlinks.json es JSON válido
curl https://deep-links-gofix.netlify.app/.well-known/assetlinks.json | jq .
# Debe retornar JSON sin errores
```

---

## 🚀 Cómo Desplegar

### Opción 1: Git (Recomendado)

```bash
# En tu repositorio local
echo "_redirects" >> .gitignore (si no está)

# Crear/actualizar archivo
cat > _redirects << 'EOF'
# ==================== WELL-KNOWN ====================
/well-known/* /.well-known/:splat 200!

# ==================== HEADERS ====================
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
EOF

# Hacer commit y push
git add _redirects reset-password/index.html confirm-email/index.html .well-known/assetlinks.json
git commit -m "feat: add Netlify deep link configuration"
git push
```

### Opción 2: Netlify UI

1. Ir a [app.netlify.com](https://app.netlify.com)
2. Seleccionar tu sitio
3. **Settings** → **Build & Deploy** → **Build settings**
4. Si usas Git, el `_redirects` se desplegará automáticamente
5. Si despliegas manualmente:
   - **Deploys** → **Deploy settings**
   - Subir la carpeta con los archivos HTML

### Opción 3: Netlify CLI

```bash
# Instalar
npm install -g netlify-cli

# Login
netlify login

# Desplegar
netlify deploy --prod --dir=.

# O específicamente
netlify deploy --prod --dir=./public
```

---

## 📝 Notas Importantes

### Content-Type para assetlinks.json

Asegúrate de que `assetlinks.json` se sirve como `application/json`:

```bash
# Verificar
curl -I https://deep-links-gofix.netlify.app/.well-known/assetlinks.json

# Esperado:
# Content-Type: application/json
```

Si no dice `application/json`, actualiza la configuración en `_redirects`.

### Cache de assetlinks.json

Es importante que `assetlinks.json` **NO** se cachee demasiado, porque:
- Android lo verifica periódicamente
- Si cambias el SHA256 (nuevo keystore), necesita actualizar rápido

Por eso configuramos:
```
Cache-Control = "no-cache"
```

### Headers de Seguridad

Los headers en `_redirects` protegen tu sitio:
- `X-Content-Type-Options`: Evita que el navegador adivine el tipo MIME
- `X-Frame-Options`: Previene clickjacking
- `X-XSS-Protection`: Protege contra XSS básicos
- `Referrer-Policy`: Controla qué información se envía

---

## 🔧 Troubleshooting

### "assetlinks.json no se encuentra"

```bash
# Verificar que existe
curl https://deep-links-gofix.netlify.app/.well-known/assetlinks.json

# Si no aparece, verificar:
# 1. Que el archivo existe en .well-known/assetlinks.json (sin punto inicial)
# 2. Que _redirects tiene: /well-known/* /.well-known/:splat 200!
# 3. Hacer re-deploy forzado
```

### "Content-Type no es application/json"

```bash
# Si retorna text/html en lugar de application/json:
curl -I https://deep-links-gofix.netlify.app/.well-known/assetlinks.json

# Solución:
# 1. Asegurar que en _redirects está:
#    Content-Type = "application/json"
# 2. O crear un netlify.toml con:
#    [[redirects]]
#      from = "/.well-known/assetlinks.json"
#      to = "/well-known/assetlinks.json"
#      status = 200
#      headers = { Content-Type = "application/json" }
```

### "Los deep links no abren la app"

Verificar en orden:
1. ✅ assetlinks.json es válido (contiene SHA256 correcto)
2. ✅ SHA256 coincide con tu certificado de firma
3. ✅ App está instalada en el dispositivo
4. ✅ Abrir Settings → Apps → Almacenamiento → Borrar cache de la app
5. ✅ Desinstalar y reinstalar la app
6. ✅ Esperar 24-48 horas (Android cachea App Links)

---

## 📚 Referencias

- [Netlify Redirects & Rewrites](https://docs.netlify.com/routing/redirects/)
- [Netlify Headers](https://docs.netlify.com/routing/headers/)
- [Android App Links](https://developer.android.com/training/app-links)
- [assetlinks.json Format](https://developers.google.com/digital-asset-links/v1/getting-started)

---

**Última Actualización:** 28 de Enero, 2026

#!/bin/sh

# Salir si ocurre un error
set -e

# Descargar Flutter 3.32.8 (Dart 3.8.1)
echo "📦 Descargando Flutter..."
curl -sL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.32.8-stable.tar.xz | tar xJ

# Agregar Flutter al PATH
export PATH="$PWD/flutter/bin:$PATH"

# Asegurar permisos de ejecución
chmod +x flutter/bin/flutter

# Configurar git seguro (para evitar errores en entornos CI/CD como Vercel)
git config --global --add safe.directory "$(pwd)/flutter"

# Verificar instalación
flutter doctor -v

# Descargar dependencias
echo "📦 Instalando dependencias..."
flutter pub get

# Compilar para web
echo "🚀 Compilando aplicación Web..."
flutter build web --release

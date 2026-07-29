#!/bin/bash
# ============================================================
# SETUP SHARE EXTENSION - Novios iOS App
# ============================================================
# Este script agrega el Share Extension al proyecto Xcode
# 
# REQUISITOS:
# - Xcode 15+ instalado
# - CocoaPods instalado (gem install cocoapods)
#
# USO:
#   1. Cierra Xcode si está abierto
#   2. Abre Terminal en esta carpeta
#   3. Ejecuta: chmod +x setup_share_extension.command
#   4. Ejecuta: ./setup_share_extension.command
# ============================================================

echo "🚀 Configurando Share Extension para Novios..."
echo ""

# 1. Verificar CocoaPods
if ! command -v pod &> /dev/null; then
    echo "❌ CocoaPods no encontrado. Instalando..."
    sudo gem install cocoapods
fi

# 2. Instalar pods (incluye ShareExtension target)
echo "📦 Instalando pods..."
pod install --repo-update

# 3. Abrir Xcode workspace
echo "📱 Abriendo Xcode..."
open Novios.xcworkspace

echo ""
echo "✅ Listo! Ahora en Xcode:"
echo ""
echo "   1. File → Add Files to 'Novios'"
echo "   2. Selecciona la carpeta ShareExtension/"
echo "   3. Marca 'Copy items if needed'"
echo "   4. Add → Create folder references"
echo "   5. Selecciona Novios.xcodeproj → TARGETS → + → Share Extension"
echo "      (Nombrala 'ShareExtension', lenguaje Swift)"
echo "   6. Reemplaza ShareViewController.swift con el nuestro"
echo "   7. En Capabilities, activa App Groups con: group.com.novios.share"
echo "   8. Build → Run"
echo ""
echo "📱 La extensión aparecerá en el Share Sheet de iOS"
echo "   Al compartir desde WhatsApp → 'Novios' → se guarda en Firestore"

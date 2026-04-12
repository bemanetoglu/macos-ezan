#!/bin/bash
set -e

APP_NAME="EzanVakti"
APP_DIR="${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "Derlemeye başlanıyor..."

# Klasörleri oluştur
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Swift dosyalarını bul ve swiftc ile derle
SWIFT_FILES=$(find Sources -name "*.swift")
swiftc -o "${MACOS_DIR}/${APP_NAME}" $SWIFT_FILES -target arm64-apple-macosx13.0 -O

echo "Swift derlemesi tamamlandı."

# AppIcon kopyala
if [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns "${RESOURCES_DIR}/"
fi


# Info.plist oluştur
cat <<EOF > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.burhanemanetoglu.${APP_NAME}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Uygulama otomatik konumunuzu bularak bulunduğunuz yerin namaz vakitlerini getirmek için konum iznine ihtiyaç duyar.</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon.icns</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
</dict>
</plist>
EOF

echo "Info.plist oluşturuldu."

echo "Uygulama paketi başarıyla oluşturuldu: ${APP_DIR}"
echo "Çalıştırmak için: open ${APP_DIR}"

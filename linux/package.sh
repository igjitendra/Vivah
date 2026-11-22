#!/bin/bash
set -e

bundle=build/linux/x64/release/bundle
out=build/linux/package
tool=https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
runtime=https://github.com/AppImage/type2-runtime/releases/download/continuous/runtime-x86_64

rm -rf "$out"
mkdir -p "$out/Vyavahaar" "$out/AppDir/usr/bin"

cp -r "$bundle"/. "$out/Vyavahaar/"
tar -C "$out" -czf Vyavahaar-linux-x64.tar.gz Vyavahaar

cp -r "$bundle"/. "$out/AppDir/usr/bin/"
cp "$bundle/com.procsctools.vyavahaar.desktop" "$bundle/com.procsctools.vyavahaar.png" "$out/AppDir/" 2>/dev/null || true
ln -sf com.procsctools.vyavahaar.png "$out/AppDir/.DirIcon" 2>/dev/null || true
ln -sf usr/bin/vyavahaar "$out/AppDir/AppRun"

curl -fsSL -o "$out/appimagetool" "$tool"
curl -fsSL -o "$out/runtime" "$runtime"
chmod +x "$out/appimagetool"
ARCH=x86_64 "$out/appimagetool" --appimage-extract-and-run --runtime-file "$out/runtime" "$out/AppDir" Vyavahaar-x86_64.AppImage

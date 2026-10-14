#!/bin/sh
# Turn the VLC.app made by extras/package/macosx/build.sh into an app that
# opens the Qt interface and runs on a Mac without Homebrew:
#  - copy vlc-qt-check, which the Qt interface runs before it starts, next to
#    the VLC binary, where the bundle looks for helper programs;
#  - remove the macOS interface, so that the Qt interface is the default;
#  - copy the Qt frameworks, plugins and QML modules into the bundle with
#    macdeployqt;
#  - sign the bundle again (ad-hoc), since the steps above change it.
#
# Usage: bundle-qt-macos.sh <build dir> <source dir>

set -e

builddir="$1"
srcdir="$2"
app="$builddir/VLC.app"

if [ ! -d "$app" ]; then
    echo "No VLC.app in $builddir" >&2
    exit 1
fi

if [ ! -e "$app/Contents/Frameworks/plugins/libqt_plugin.dylib" ]; then
    echo "The Qt interface was not built (libqt_plugin.dylib is missing)" >&2
    exit 1
fi

qtcheck=$(find "$builddir/macos-install" -name vlc-qt-check -type f | head -n 1)
if [ -z "$qtcheck" ]; then
    echo "vlc-qt-check was not installed" >&2
    exit 1
fi
cp "$qtcheck" "$app/Contents/MacOS/vlc-qt-check"

rm -f "$app/Contents/Frameworks/plugins/libmacosx_plugin.dylib"

macdeployqt "$app" \
    -executable="$app/Contents/Frameworks/plugins/libqt_plugin.dylib" \
    -executable="$app/Contents/MacOS/vlc-qt-check" \
    -qmldir="$srcdir/modules/gui/qt" \
    -always-overwrite \
    -verbose=1

# The plugin cache lists the plugins of the bundle, so it is generated again.
if [ -x "$builddir/bin/vlc-cache-gen" ]; then
    VLC_LIB_PATH="$app/Contents/Frameworks" "$builddir/bin/vlc-cache-gen" "$app/Contents/Frameworks/plugins"
fi

codesign --force --deep --sign - "$app"
codesign --verify --deep "$app"

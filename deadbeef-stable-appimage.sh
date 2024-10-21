#!/bin/sh

set -u
APP=deadbeef-stable
SITE=$(wget -q https://sourceforge.net/projects/deadbeef/files/travis/linux/ -O - \
  | grep -Eo "(http|https)://[a-zA-Z0-9./?=_%:-]*" | grep download | grep -vE 'master|feature|bugfix' | head -1 | sed 's/download//g')

# DOWNLOAD THE ARCHIVE
mkdir -p "./$APP/tmp" && cd "./$APP/tmp" || exit 1
version=$(wget -q "$SITE" -O - | grep -Eo "(http|https)://[a-zA-Z0-9./?=_%:-]*" | sort -u | grep "x86_64.tar.bz2")
wget $version -O download.tar.bz2 && tar fx ./*tar* || exit 1
cd ..
mkdir -p "./$APP.AppDir/usr/bin" && mv --backup=t ./tmp/*/* "./$APP.AppDir/usr/bin"
cd ./$APP.AppDir || exit 1

# DESKTOP ENTRY AND ICON
DESKTOP="https://raw.githubusercontent.com/DeaDBeeF-Player/deadbeef/master/deadbeef.desktop.in"
ICON="https://raw.githubusercontent.com/DeaDBeeF-Player/deadbeef/master/icons/scalable/deadbeef.svg"
wget $DESKTOP -O ./$APP.desktop && wget $ICON -O ./deadbeef.svg && ln -s deadbeef.svg ./.DirIcon

# AppRun
cat >> ./AppRun << 'EOF'
#!/bin/sh
CURRENTDIR="$(readlink -f "$(dirname "$0")")"
exec "$CURRENTDIR"/usr/bin/deadbeef "$@"
EOF
chmod a+x ./AppRun

# MAKE APPIMAGE
cd ..
APPIMAGETOOL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
wget -q "$APPIMAGETOOL" -O ./appimagetool
chmod a+x ./appimagetool

# Do the thing!
export ARCH=x86_64 
export VERSION=$(wget -q "$SITE" -O - | sed 's/"/ /g' | grep "files_date" | grep -o "[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}" | head -1)
./appimagetool --comp zstd --mksquashfs-opt -Xcompression-level --mksquashfs-opt 20 \
  -u "gh-releases-zsync|$GITHUB_REPOSITORY_OWNER|DeaDBeeF-AppImage|continuous|*Stable*$ARCH.AppImage.zsync" \
  ./"$APP".AppDir DeaDBeeF_Stable-"$VERSION"-"$ARCH".AppImage 
[ -n "$APP" ] && mv ./*.AppImage* .. && cd .. && rm -rf ./"$APP" || exit 1
echo "All Done!"

#!/bin/sh

set -eu

APP=DeaDBeeF
SITE="https://sourceforge.net/projects/deadbeef/files/travis/linux/master"
TARGET_BIN="deadbeef"
DESKTOP="https://raw.githubusercontent.com/DeaDBeeF-Player/deadbeef/master/deadbeef.desktop.in"
ICON="https://raw.githubusercontent.com/DeaDBeeF-Player/deadbeef/master/icons/scalable/deadbeef.svg"

export ARCH="$(uname -m)"
export APPIMAGE_EXTRACT_AND_RUN=1
export VERSION=$(wget -q "$SITE" -O - | sed 's/"/ /g' | grep "files_date" | grep -o "[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}" | head -1)

APPIMAGETOOL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-$ARCH.AppImage"
UPINFO="gh-releases-zsync|$(echo $GITHUB_REPOSITORY | tr '/' '|')|continuous|*$ARCH.AppImage.zsync"
LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"

# Prepare AppDir
mkdir -p "$APP"/AppDir/shared/share/applications
cd "$APP"/AppDir
url="$(wget -q "$SITE" -O - | grep -Eo "(http|https)://[a-zA-Z0-9./?=_%:-]*" | sort -u | grep "x86_64.tar.bz2")"
wget $url -O download.tar.bz2
tar fx ./*.tar*
rm -f ./*.tar*

mv ./deadbeef* ./shared/bin
ln -s ./bin/lib ./shared/lib
ln -s ./shared ./usr

wget "$DESKTOP" -O ./"$APP".desktop
wget "$ICON" -O ./deadbeef.svg
sed -i 's/DeaDBeeF/DeaDBeeF Nightly/g' ./"$APP".desktop
cp ./"$APP".desktop ./usr/share/applications

# ADD LIBRARIES
# not bundling GTK2
find . -type f -iname '*GTK2*' -delete
wget "$LIB4BN" -O ./lib4bin
chmod +x ./lib4bin
./lib4bin -v -r -w ./shared/bin/"$TARGET_BIN"

ln ./sharun ./AppRun
find ./shared/lib -type f -name '*.so*' -exec ldd {} \; \
	| awk -F"[> ]" '{print $4}' | xargs -I {} cp -vn {} ./shared/lib
./sharun -g

# DEPLOY GDK
#echo "Deploying gdk..."
#GDK_PATH="$(find /usr/lib -type d -regex ".*/gdk-pixbuf-2.0" -print -quit)"
#cp -rv "$GDK_PATH" ./shared/lib

#echo "Deploying gdk deps..."
#find ./shared/lib/gdk-pixbuf-2.0 -type f -name '*.so*' -exec ldd {} \; \
#	| awk -F"[> ]" '{print $4}' | xargs -I {} cp -vn {} ./shared/lib
#find ./shared/lib -type f -regex '.*gdk.*loaders.cache' \
#	-exec sed -i 's|/.*lib.*/gdk-pixbuf.*/.*/loaders/||g' {} \;

# Strip everything
find ./shared -type f -exec strip -s -R .comment --strip-unneeded {} ';'

# MAKE APPIAMGE WITH FUSE3 COMPATIBLE APPIMAGETOOL
cd ..
wget -q "$APPIMAGETOOL" -O ./appimagetool
chmod +x ./appimagetool

./appimagetool --comp zstd \
	--mksquashfs-opt -Xcompression-level --mksquashfs-opt 22 \
	-n -u "$UPINFO" "$PWD"/AppDir "$PWD"/"$APP"-"$VERSION"-"$ARCH".AppImage

mv ./*.AppImage* ../
cd ..
#rm -rf ./"$APP"
echo "All Done!"

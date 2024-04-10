#!/bin/sh

APP=deadbeef

# Create folders
if [ -z "$APP" ]; then exit 1; fi
mkdir -p ./$APP/tmp && cd ./$APP/tmp

# DOWNLOAD THE ARCHIVE
version=$(wget -q https://sourceforge.net/projects/deadbeef/files/travis/linux/master/ -O - | grep -Eo "(http|https)://[a-zA-Z0-9./?=_%:-]*" | sort -u | grep "x86_64.tar.bz2")
wget $version -O download.tar.bz2
echo "$version" >> ./version
tar fx ./*tar*
cd ..
mkdir ./$APP.AppDir
mv --backup=t ./tmp/*/* ./$APP.AppDir
rm -rf "./tmp"

cd ./$APP.AppDir

# DESKTOP ENTRY
echo "[Desktop Entry]
Type=Application
Name=DeaDBeeF Nightly

Exec=deadbeef %F
Icon=deadbeef

GenericName=Audio Player
GenericName[pt_BR]=Reprodutor de áudio
GenericName[ru]=Аудио плеер
GenericName[zh_CN]=音频播放器
GenericName[zh_TW]=音樂播放器
Comment=Listen to music
Comment[pt_BR]=Escute músicas
Comment[ru]=Слушай музыку
Comment[zh_CN]=倾听音乐
Comment[zh_TW]=聆聽音樂
MimeType=application/ogg;audio/x-vorbis+ogg;application/x-ogg;audio/mp3;audio/prs.sid;audio/x-flac;audio/mpeg;audio/x-mpeg;audio/x-mod;audio/x-it;audio/x-s3m;audio/x-xm;audio/x-mpegurl;audio/x-scpls;application/x-cue;
Categories=Audio;AudioVideo;Player;GTK;
Keywords=Sound;Music;Audio;Player;Musicplayer;MP3;
Terminal=false
Actions=Play;Pause;Toggle-Pause;Stop;Next;Prev;
X-Ayatana-Desktop-Shortcuts=Play;Pause;Stop;Next;Prev;
X-PulseAudio-Properties=media.role=music

[Desktop Action Play]
Name=Play
Name[zh_CN]=播放
Name[zh_TW]=播放
Exec=deadbeef --play

[Desktop Action Pause]
Name=Pause
Name[zh_CN]=暂停
Name[zh_TW]=暫停
Exec=deadbeef --pause

[Desktop Action Toggle-Pause]
Name=Toggle Pause
Name[zh_CN]=播放/暂停
Name[zh_TW]=播放/暫停
Exec=deadbeef --toggle-pause

[Desktop Action Stop]
Name=Stop
Name[zh_TW]=停止
Exec=deadbeef --stop

[Desktop Action Next]
Name=Next
Name[zh_TW]=下一首
Exec=deadbeef --next

[Desktop Action Prev]
Name=Prev
Name[zh_TW]=上一首
Exec=deadbeef --prev" >> ./$APP.desktop

# Icon
wget https://raw.githubusercontent.com/DeaDBeeF-Player/deadbeef/master/icons/scalable/deadbeef.svg -O ./deadbeef.svg 2> /dev/null
ln -s ./deadbeef.svg ./.DirIcon

# AppRun
cat >> ./AppRun << 'EOF'
#!/bin/sh
CURRENTDIR="$(readlink -f "$(dirname "$0")")"
exec "$CURRENTDIR"/deadbeef "$@"
EOF
chmod a+x ./AppRun

# MAKE APPIMAGE
cd ..
wget -q $(wget -q https://api.github.com/repos/probonopd/go-appimage/releases -O - | grep -v zsync | grep -i continuous | grep -i appimagetool | grep -i x86_64 | grep browser_download_url | cut -d '"' -f 4 | head -1) -O appimagetool
chmod a+x ./appimagetool

# Do the thing!
ARCH=x86_64 VERSION=$(./appimagetool -v | grep -o '[[:digit:]]*') ./appimagetool -s ./$APP.AppDir &&
ls ./*.AppImage || { echo "appimagetool failed to make the appimage"; exit 1; }

VERSION=$(wget -q https://sourceforge.net/projects/deadbeef/files/travis/linux/master/ -O - | sed 's/"/ /g' | grep "files_date" | grep -o "[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}" | head -1)
NAME=$(ls *AppImage)
mv ./*AppImage ./"$VERSION"-"$NAME"

# Clean up
if [ -z "$APP" ]; then exit 1; fi # Being extra safe lol
rm -rf "./$APP.AppDir"
rm ./appimagetool
mv ./*.AppImage ..
echo "All Done!"

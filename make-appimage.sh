#!/bin/sh

set -eu

ARCH=$(uname -m)
export ARCH
export OUTPATH=./dist
export ADD_HOOKS="self-updater.bg.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export DESKTOP="https://raw.githubusercontent.com/DeaDBeeF-Player/deadbeef/master/deadbeef.desktop.in"
export ICON="https://raw.githubusercontent.com/DeaDBeeF-Player/deadbeef/master/icons/scalable/deadbeef.svg"
export DEPLOY_PIPEWIRE=1

# Deploy dependencies
quick-sharun \
	./AppDir/bin/*    \
	/usr/bin/faac     \
	/usr/bin/flac     \
	/usr/bin/lame     \
	/usr/bin/mpcenc   \
	/usr/bin/oggenc   \
	/usr/bin/opusenc  \
	/usr/bin/wavpack

# Additional changes can be done in between here

# Turn AppDir into AppImage
quick-sharun --make-appimage

# Test the final app
quick-sharun --test ./dist/*.AppImage

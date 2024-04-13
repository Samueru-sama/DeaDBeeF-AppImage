# DeaDBeeF-AppImage
Unofficial AppImage of the DeaDBeeF music player: https://github.com/DeaDBeeF-Player/deadbeef

Uses the portable builds of DeaDBeeF from here and turns them into an AppImages: https://sourceforge.net/projects/deadbeef/files/travis/linux/

You can also run the `deadbeef-appimage.sh` or `deadbeef-stable-appimage.sh` script in your machine to make the AppImage.

It is possible that these appimages may fail to work with appimagelauncher, since appimagelauncher is pretty much dead I recommend this alternative: https://github.com/ivan-hc/AM

This appimage works without `fuse2` as it can use `fuse3` instead, however you will need to run this command to symlink fusermount to fusermount3 otherwise you will get a missing fusermount error: 

`sudo ln -s /usr/bin/fusermount3 /usr/bin/fusermount`

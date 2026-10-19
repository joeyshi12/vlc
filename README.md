# VLC media player

This is a fork of VLC 4 (the development branch) with a redesigned Qt interface.
The design is by [Juxtopposed](https://www.youtube.com/@juxtopposed), from their
VLC redesign concept. This fork implements that design in VLC's QML interface and
adds a few fixes.

## Interface changes

- **Navigation panel**: a rounded panel with gaps around it and outline SVG icons.
  The current page is shown in the accent colour. Video is renamed to Videos and
  Browse to Network.
- **Home page**: Continue Watching, Listen Again (recently played audio) and
  Frequently Visited Folders replace Favorites, New Videos and New Music.
- **Control bar**: previous, play and next, the time and seek bar, the volume and
  the remaining buttons sit in one row. The volume is a wedge that fills from
  green to red.
- **Seek bar**: shows the audio level for audio files. For videos it can show
  where subtitle lines are, with "Show Subtitle Timeline on Seekbar" in the
  playback settings.
- **Side panels**: the play queue button opens a panel with Queue, Bookmarks and
  Chapters tabs. Separate buttons open a player settings panel with Playback,
  Video, Audio and Subtitles tabs, which cover tracks, delays, speed and a sleep
  timer.
- **Mini player**: a card at the bottom right of the library with the video,
  seek bar, title, folder and artist. The controls appear on hover, and the
  video has rounded corners. The queue opens as its own panel and the mini
  player moves left to make room.
- **Settings**: opened from the top menu instead of the navigation panel.
- **Other screens**: the library header, page menus, playlists, onboarding,
  keyboard shortcuts, and the network stream, playlist and subtitle dialogs use
  the redesign, with its colours in both the light and dark themes.
- Clickable controls show the hand cursor.

## Fixes

- Fixed a crash on startup when the settings hold a graphics API from a previous
  run.
- On X11, the interface no longer disappears over the video after the window is
  resized.
- YouTube videos played through yt-dlp no longer play without sound. When no
  format has both audio and video, VLC opens the HLS manifest instead.
- The media library builds against current medialibrary master.

## Installing

There are no prebuilt binaries, so this fork has to be built from source. It is
based on VLC 4, while most distributions ship VLC 3, and it needs a media
library built from git. Install `yt-dlp` to play YouTube and other web videos.

### Arch Linux

`extras/package/arch/PKGBUILD` builds this fork with the media library and
installs it to `/opt/vlc`, with `/usr/bin/vlc`, a desktop entry and icons:

```
cd extras/package/arch && makepkg -si
```

The package conflicts with Arch's `vlc` package.

### Other Linux distributions

These steps follow the PKGBUILD and install everything to `/opt/vlc`, so they
don't clash with the distribution's VLC 3.

1. Install the build tools and libraries. You need Meson 1.10 or later
   (`pip install --user meson` if your distribution's is older), Ninja, a C and
   C++ compiler, Qt 6.2 or later with Qt Declarative, Qt SVG and Qt Shader
   Tools, and the development packages for the libraries VLC uses. The
   `depends` and `makedepends` lists in `extras/package/arch/PKGBUILD` name
   them. On Debian and Ubuntu, `sudo apt build-dep vlc` installs most of them,
   with Qt 5 in place of Qt 6.

2. Get the sources. libvlcpp and medialibrary are pinned to the commits that
   build with this tree:

   ```
   git clone https://github.com/joeyshi12/vlc.git
   git clone https://code.videolan.org/videolan/libvlcpp.git
   git -C libvlcpp checkout 3095992b779ef7ee4487f39f936f8ab3750cb23a
   git clone https://code.videolan.org/videolan/medialibrary.git
   git -C medialibrary checkout 5528c2faabfe04ce96e7b26d2dcf6ce742568c79
   ```

3. Build VLC, then libvlcpp and medialibrary against it, then VLC again so
   that it includes the media library plugin:

   ```
   prefix=/opt/vlc
   export PKG_CONFIG_PATH=$prefix/lib/pkgconfig
   export LDFLAGS="-Wl,-rpath,$prefix/lib:$prefix/lib/vlc"
   opts="--prefix=$prefix --libdir=lib --buildtype=release"

   meson setup build-vlc vlc $opts -Dvulkan=disabled
   meson compile -C build-vlc && sudo meson install -C build-vlc

   meson setup build-libvlcpp libvlcpp $opts -Dtests=disabled -Dexamples=disabled
   sudo meson install -C build-libvlcpp
   meson setup build-medialibrary medialibrary $opts -Dtests=disabled
   meson compile -C build-medialibrary && sudo meson install -C build-medialibrary

   meson setup --reconfigure build-vlc vlc
   meson compile -C build-vlc && sudo meson install -C build-vlc
   sudo $prefix/libexec/vlc/vlc-cache-gen $prefix/lib/vlc/plugins
   ```

4. Run it with `/opt/vlc/bin/vlc`, or link it into your `PATH`:
   `sudo ln -s /opt/vlc/bin/vlc /usr/local/bin/vlc`.

### Windows

VLC for Windows is cross-compiled with mingw-w64 from Linux, WSL or msys2. MSVC
is not supported. The quickest setup is VideoLAN's Docker image, which has the
toolchain installed:

```
git clone https://github.com/joeyshi12/vlc.git
docker run -it --rm -v "$PWD/vlc:/vlc" -w /vlc \
    registry.videolan.org/vlc-debian-win64:latest bash
```

Inside the container, or in a WSL or msys2 shell set up as described in
[doc/BUILD-win32.md](doc/BUILD-win32.md):

```
mkdir win64 && cd win64
../extras/package/win32/build.sh -a x86_64 -r -m -i r
```

This builds the third-party libraries under `contrib/`, which takes a long
time on the first run, then VLC, and writes an NSIS installer (`vlc-*.exe`) to
`win64/`. Use `-i u` for a zip archive instead of an installer. Copy the file
to Windows and run it.

The contrib build uses medialibrary 0.13.2, which is older than the version
this fork's media library module is written for, so that module does not
compile yet on Windows. The X11 fix above does not apply on Windows.

The license is the same as upstream VLC: GPLv2 or later, and LGPLv2 or later
for libVLC.

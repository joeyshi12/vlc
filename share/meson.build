fs = import('fs')

# Desktop entries (freedesktop.org platforms only)
if host_system not in ['windows', 'darwin', 'android']
    # Same transformation as share/Makefile.am: strip comments and blank
    # lines, then join with ';' (every entry, including the last, ends in ';').
    desktop_mimetypes = []
    foreach line : fs.read('vlc.desktop.mimetypes').split('\n')
        line = line.split('#')[0].strip()
        if line != ''
            desktop_mimetypes += line
        endif
    endforeach

    desktop_conf = configuration_data()
    desktop_conf.set('bindir', bindir_path)
    desktop_conf.set('MIMETYPES', ';'.join(desktop_mimetypes) + ';')

    desktop_file_validate = find_program('desktop-file-validate', required: false)

    foreach name : ['vlc', 'vlc-openbd', 'vlc-opendvd', 'vlc-openvcd', 'vlc-opencda']
        desktop_file = configure_file(
            input: name + '.desktop.in',
            output: name + '.desktop',
            configuration: desktop_conf,
            install: true,
            install_dir: sysdatadir_path / 'applications',
        )
        if desktop_file_validate.found()
            test('desktop-file-validate ' + name, desktop_file_validate,
                 args: [desktop_file])
        endif
    endforeach
endif

# Icons
if host_system != 'windows'
    install_data('icons/vlc.ico', install_dir: pkgdatadir_path)

    hicolor_dir = sysdatadir_path / 'icons' / 'hicolor'
    vlc_icons = {
        '16x16': ['vlc.png', 'vlc.xpm'],
        '32x32': ['vlc.png', 'vlc.xpm', 'vlc-xmas.xpm', 'vlc-aprilfools.xpm'],
        '48x48': ['vlc.png', 'vlc-xmas.png', 'vlc-aprilfools.png'],
        '128x128': ['vlc.png', 'vlc-xmas.png', 'vlc-kb.png', 'vlc-aprilfools.png'],
        '256x256': ['vlc.png'],
    }
    foreach size, icon_files : vlc_icons
        foreach f : icon_files
            install_data('icons' / size / f, install_dir: hicolor_dir / size / 'apps')
        endforeach
    endforeach
endif

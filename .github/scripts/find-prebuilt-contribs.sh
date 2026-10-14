#!/bin/sh
# Print the URL of the newest prebuilt contrib archive published by the
# VideoLAN CI for this source tree, or exit with an error if there is none.
#
# The VideoLAN CI names each archive after the last commit that changed the
# contrib build (see extras/ci/get-contrib-sha.sh). Archives are not published
# for every commit, so this walks back through those commits and takes the
# first one that has an archive.
#
# Usage: find-prebuilt-contribs.sh <job group> <triplet> <package dir>
#   job group:   folder on artifacts.videolan.org, for example "win64"
#   triplet:     contrib host triplet, for example "x86_64-w64-mingw32"
#   package dir: folder under extras/package, for example "win32"

set -e

group="$1"
triplet="$2"
package="$3"

if [ -z "$group" ] || [ -z "$triplet" ] || [ -z "$package" ]; then
    echo "usage: $0 <job group> <triplet> <package dir>" >&2
    exit 2
fi

base="https://artifacts.videolan.org/vlc/$group"

for sha in $(git rev-list -n 60 HEAD -- extras/tools contrib extras/ci "extras/package/$package"); do
    url="$base/vlc-contrib-$triplet-$sha.tar.zst"
    if curl -sfIL -o /dev/null "$url"; then
        echo "$url"
        exit 0
    fi
done

echo "No prebuilt contribs found in $base for the last 60 contrib commits" >&2
exit 1

#!/bin/bash

hyrax_version_class=$(
        cat << EOF
package opendap.version;

public class HyraxVersion {
    private static final String hyraxVersion = "$HYRAX_VERSION";
    public static String getVersionString() { return hyraxVersion; }
}
EOF
    )

target_dir="$TRAVIS_BUILD_DIR/$TARGET_OS-builds/$DOCKER_DIR"
echo "# target_dir: $target_dir" >&2

target_file="$target_dir/HyraxVersion.java"
echo "# target_file: $target_file" >&2

echo "$hyrax_version_class" > "$target_file"
cat "$target_file" >&2

javac "$target_file"
ls -l "$target_dir/"HyraxVersion* >&2

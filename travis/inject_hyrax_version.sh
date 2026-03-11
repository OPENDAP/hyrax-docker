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

echo "$hyrax_version_class" > "$DOCKER_DIR/HyraxVersion.java"

cat HyraxVersion.java >&2
javac HyraxVersion.java
ls -l HyraxVersion* >&2

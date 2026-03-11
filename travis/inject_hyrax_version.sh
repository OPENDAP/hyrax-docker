#!/bin/bash

hyrax_version_class=$(
        cat << EOF
package opendap.version;

public class HyraxVersion {
    private static final String hyraxVersion = "@HyraxVersion@";

    /**
     * Returns a String containing the Hyrax version.
     * @return The version of Hyrax.
     */
    public static String getVersionString() { return hyraxVersion; }

}
EOF
    )

echo "${hyrax_version_class//@HyraxVersion@/$HYRAX_VERSION}" > HyraxVersion.java

loggy "cat HyraxVersion.java"
javac HyraxVersion.java
loggy "$(ls -l HyraxVersion*)"

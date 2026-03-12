#!/bin/bash
######################################################################################################
# This file builds a special HyraxVersion.java file using the current value of HYRAX_VERSION as
# defined by the production environment (see the hyrax-docker/el9-builds/build-el9 and
# hyrax-docker/el8-builds/build-el8 scripts for details)
#
# This special HyraxVersion.java file is placed in the DOCKER_DIR for the current job.
# The class is compiled using javac and the resulting HyraxVersion.class file is placed in
# the same DOCKER_DIR adjacent to the original HyraxVersion.java file.
#
# When the docker build command(s) are run, the Dockerfile unpacks the OLFS distribution into the
# Tomcat directory. Once the OLFS is unpacked the Dockerfile copies the HyraxVersion.class file into
# the $CATALINA_HOME/webapps/$DEPLOYMENT_CONTEXT/WEB-INF/classes/opendap/version directory,
# overwriting the class built and distributed by the OLFS.
#
# This allows us to have hyrax-docker set the Hyrax version numbers (since hyrax-docker is in fact
# the assembler of the Hyrax docker images and thus the responsible party)
#
#
# Here is the java code as a Here Document. Note that $HYRAX_VERSION is substituted when
# the script is run.
#
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

docker build --build-arg RELEASE_DATE=1 \
       --build-arg AWS_ACCESS_KEY_ID=AKIA24JBYMSH2R2CR2X2 \
       --build-arg AWS_SECRET_ACCESS_KEY=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 \
       --build-arg LIBDAP_VERSION=3.20.7-21 \
       --build-arg BES_VERSION=3.20.8-48 \
       --build-arg OLFS_VERSION=1.18.8-79 \
       --build-arg HYRAX_VERSION=1.16.3-49 \
       --tag hyrax-foo hyrax --verbose


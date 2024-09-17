FROM rocker/r-base:4.3.0

# Install library dependencies
RUN apt-get update -y && apt-get install -y  make pandoc zlib1g-dev git libicu-dev libpng-dev libgdal-dev gdal-bin libgeos-dev libproj-dev libsqlite3-dev libxml2-dev libudunits2-dev && rm -rf /var/lib/apt/lists/*

# Java
ENV DEBIAN_FRONTEND=noninteractive
ARG JAVA_VERSION
ENV JAVA_HOME=/usr/lib/jvm/java-$JAVA_VERSION-openjdk-amd64
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get -y install openjdk-$JAVA_VERSION-jre-headless && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Prepare R
RUN mkdir -p /usr/local/lib/R/etc/ /usr/lib/R/etc/
RUN echo "options(renv.config.pak.enabled = FALSE, repos = c(CRAN = 'https://cran.rstudio.com/'), download.file.method = 'libcurl', Ncpus = 4)" | tee /usr/local/lib/R/etc/Rprofile.site | tee /usr/lib/R/etc/Rprofile.site
RUN R -e 'install.packages("remotes")'
RUN R -e 'remotes::install_version("renv", version = "1.0.3")'

# Restore renv environment
COPY renv.lock renv.lock
ENV RENV_PATHS_LIBRARY=renv/library
RUN R -e 'renv::restore()'

# NetLogo
ARG NETLOGO_FILE
ARG NETLOGO_VERSION
ADD $NETLOGO_FILE /

# HyperQueue
ARG HQ_FILE
ADD $HQ_FILE /usr/bin/

# Prepare input/output folder
RUN mkdir -p /input
RUN mkdir -p /output

ENV JAVA_HOME=/usr/lib64/jvm/java-$JAVA_VERSION-openjdk-$JAVA_VERSION \
    NETLOGO_HOME="/NetLogo $NETLOGO_VERSION" \
    NETLOGO_VERSION=$NETLOGO_VERSION \
    #PROJ_DATA=/conda/env/share/proj \
    PATH=/usr/bin:$PATH \
    LC_ALL=C.UTF-8

COPY R /R
COPY scripts /scripts

ENTRYPOINT ["/scripts/cloud/run_docker_flow.sh"]
CMD ["--help"]

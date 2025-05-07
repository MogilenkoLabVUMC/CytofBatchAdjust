# ─── base ──────────────────────────────────────────────────────────────────────
# R-4.4.x is the last Bioconductor-supported series (Bioc 3.20). 4.5.0 is
# brand-new and not yet in sync with Bioconductor, so we pin to 4.4.3.
FROM rocker/r-ver:4.4.3

LABEL maintainer="Anton Zhelonkin <anton.bioinf.md@gmail.com>"

# ─── system libs needed by flowCore & friends ─────────────────────────────────
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
        libcurl4-openssl-dev libxml2-dev libssl-dev \
        libcairo2-dev libfreetype6-dev libpng-dev libjpeg-dev fonts-dejavu-core \
        && rm -rf /var/lib/apt/lists/*

# ─── R packages ───────────────────────────────────────────────────────────────
RUN R -q -e "install.packages('BiocManager', repos='https://cran.rstudio.com/')" \
    && R -q -e "BiocManager::install('flowCore', update = FALSE, ask = FALSE)"

# ─── app code ─────────────────────────────────────────────────────────────────
# Keep script immutable inside the image; mount data separately.
COPY Scripts/BatchAdjust.R /opt/batchadjust/BatchAdjust.R

# Lightweight wrapper so users can just pass R args to `docker run …`
COPY Scripts/docker-wrapper.R /usr/local/bin/batchadjust
RUN chmod +x /usr/local/bin/batchadjust

WORKDIR /workspace
ENTRYPOINT ["batchadjust"]
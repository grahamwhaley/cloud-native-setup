# Copyright (c) 2018-2019 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0

# Set up an Ubuntu image with the components needed to generate a
# metrics report. That includes:
#  - R
#  - The R 'tidyverse'
#  - pandoc
#  - The report generation R files and helper scripts

# Start with the base rocker tidyverse.
# We would have used the 'verse' base, that already has some of the docs processing
# installed, but I could not figure out how to add in the extra bits we needed to
# the lite tex version is uses.
FROM rocker/shiny:latest

# Version of the Dockerfile
LABEL DOCKERFILE_VERSION="1.0"

# Install the extra R packages we need.
RUN install2.r --error --deps TRUE \
	gridExtra \
	ggpubr

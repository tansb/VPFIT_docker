# Use a Linux base image that supports ARM64 incase installing on an M1 Mac
# chose debian bullseye because its lightweight but an official distribution
FROM debian:bullseye

# Set environment variables for non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies if needed (e.g. unzip, tar)
# The CFITSIO library is required for VPfit
# libpng for PNG support
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
    gfortran \
    csh \
    gdb \
    make \
    wget \
    unzip \
    pip \
    vim \
    x11-apps \
    libcfitsio-dev \
    libpng-dev \
    libx11-dev \
    && rm -rf /var/lib/apt/lists/*

# Download PGPlot (dependency of vpfit)
# Follow the instructions for installing PGPLOT from
# https://guaix.fis.ucm.es/~ncl/howto/howto-pgplot
RUN cd /usr/local/src \
    && wget ftp://ftp.astro.caltech.edu/pub/pgplot/pgplot5.2.tar.gz \
    && tar zxvf pgplot5.2.tar.gz \
    # Create the directory where PGPLOT will be actually installed:
    && mkdir /usr/local/pgplot \
    && cd /usr/local/pgplot \
    # Copy the file drivers.list from the source directory to installation dir
    && cp /usr/local/src/pgplot/drivers.list . \
    # overwrite the dirvers.list file with the one found on the how-to with the
    # correct drivers uncommented.
    # Allow insecure HTTPS
    && wget --no-check-certificate -O /usr/local/pgplot/drivers.list https://guaix.fis.ucm.es/~ncl/howto/drivers.list \
    # Create the makefile. From the installation directory /usr/local/pgplot execute:
    && /usr/local/src/pgplot/makemake /usr/local/src/pgplot linux g77_gcc_aout \
    # Edit the file makefile and change the compiler from gcc to gfortran
    && sed -i 's/^FCOMPL=g77/FCOMPL=gfortran/' makefile \
    # Compile the source files:
    && make \
    && make cpg \
    && make clean \
    # make sure that the expected environment variables are properly set
    && echo 'export PGPLOT_DIR=/usr/local/pgplot' >> /root/.bashrc  \
    && echo 'export PGPLOT_DEV=/Xserve' >> /root/.bashrc

# Install CFITSIO
RUN cd /opt \
    && wget https://heasarc.gsfc.nasa.gov/FTP/software/fitsio/c/cfitsio-4.6.2.tar.gz \
    # uncompress
    && tar zxvf cfitsio-4.6.2.tar.gz \
    && cd cfitsio-4.6.2 \
    && ./configure --prefix=/usr/local --enable-reentrant \
    && make clean \
    && make \
    && make install

# --- 3. Refresh linker cache so libcfitsio.so is found ---
RUN ldconfig

# Install gdown, a Python-based downloader that can handle Google Drive links.
# the --break-system-packages is required because Debian-based systems enforce
# PEP 668, which prevents pip from modifying the system Python environment.
RUN pip install gdown

# Use the actual file ID from the Google Drive link
# The link is: https://drive.google.com/file/d/1kgCv7vxVhFK_87KIrcnICTexz3jIL8z_/view
# So the file ID is: 1kgCv7vxVhFK_87KIrcnICTexz3jIL8z_

# Download the file using gdown and unzip it.
RUN gdown https://drive.google.com/uc?id=1kgCv7vxVhFK_87KIrcnICTexz3jIL8z_ \
    && unzip vpfit12.4.zip \
    && cd vpfit12.4 \
    # set evironment variables according to vpfit instructions
    && csh vppreset.cmd \
    # Change the install directories for PGPLOT and CFITSIO which are hardocded
    # in the VPfit makefile
    && sed -i 's|^pgpltx =[ \t]*/home/rfc/pgplot/libpgplot.a|pgpltx = /usr/local/pgplot/libpgplot.a|' makefile \
    && sed -i 's|^cfitsx =[ \t]*/home/rfc/cfitsio/libcfitsio.a|cfitsx = /usr/local/lib/libcfitsio.a|' makefile \
    # Remove -lg2c from the link line in the makefile (not needed with gfortran compiler, was for g77 but g77 is ancient)
    && sed -i 's/-lg2c//g' makefile \
    # fix the linker to tell it where pgplot is installed
    && sed -i 's|-lpgplot|-L/usr/local/pgplot -lpgplot|g' makefile \
    # Add missing libraries
    # need to add -lpthread -lz  to line 116 to update linkers. The below line
    # just adds -lpthread -lz to the vpflx: call.
    && sed -i '/^vpflx: vpgti.o/,/\/usr\/lib\/gcc\/x86_64-redhat-linux\/3.4.6\// { \
    /\/usr\/lib\/gcc\/x86_64-redhat-linux\/3.4.6\// s|$| -lpthread -lz| \
    }' makefile \
    # execute the makefile
    && make vpflx \
    # Add an alias to the vpfit executable so it can be run from anywhere
    && echo "alias vpfit='/vpfit12.4/vpfit'" >> /etc/bash.bashrc

# set the working directory to the mount point where the data directory is mounted to
WORKDIR /mnt/

# Set bash to be the default command
CMD ["/bin/bash"]

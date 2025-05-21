# Dockerfile to build containers with Bob Carswell's VPFIT software installed

The voigt profile fitting program [VPFIT](https://people.ast.cam.ac.uk/~rfc/vpfit) written by [Bob Carswell](https://people.ast.cam.ac.uk/~rfc/) is a fortran program to fit voigt profiles to absorption features in astronomical spectra.

This dockerfile is to download and install version VPFIT.12.4 along with all its dependencies (PGPLOT, CFITSIO). The dockerfile also modifies the makefile to use the newer fortran compiler gfortran over g77.

### Step 0. Clone the repo
```bash
git clone https://github.com/tansb/VPFIT_docker.git
cd VPFIT_docker
```

### 1. Set up X11 forwarding to XQuartz

VPFIT uses the PGPLOT GUI, so you need some way to forward the display from the
container to your actual computer's display. On a mac to allow X11 access:

(a) Open XQuartz and go to Preferences > Security. Make sure "Allow connections from network clients" is enabled.

(b) Also, on your mac run the command ```xhost +``` to allow the Docker container to connect to any X11 server.

#### Step 2. Build the docker container
Docker containers are designed to work and operate in isolation, but when using VPFIT you need an easy way to pass data in and out. Therefore, specify a directory to mount into the container so you can access that data from within the container (and save the reduced files out).

```bash
export MY_MOUNTED_DATA_DIR=<your_data_dir>
```

Create the docker image and build a container
```bash
docker compose up -d
```

Enter the container
```bash
docker exec -it vpfit_container bash
```

First check that the X11 forwarding is working correctly by typing ```xeyes``` into the container terminal. A little display with cartoon eyes should pop up in an XQuartz window and follow your cursor around. If not, not sure try step 1 again?

#### Step 3. Run VPFIT
The container will open directly into your mounted data directory you defined in MY_MOUNTED_DATA_DIR.
To run vpfit, just type ```vpfit```. For instructions on running VPFIT, see the [user manual written by Bob Carswell](https://www.overleaf.com/read/vbxkcfnfgksr)



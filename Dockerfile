# syntax=docker/dockerfile:1.4.2

FROM nvidia/cuda:11.1.1-cudnn8-runtime-ubuntu20.04

##### Install requirements
RUN apt update && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC \
                   apt install -y --allow-unauthenticated \
                                  wget git vim build-essential \
                                  libosmesa6-dev libglew-dev \
                                  glibc-source unzip \
                                  mpich python3-dev python3-pip patchelf \
                                  libgl1-mesa-dev libgl1-mesa-glx \
                                  ffmpeg net-tools parallel software-properties-common \
                                  swig zlib1g-dev \
                && apt-get clean \
                && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install pip --upgrade pip

#### set directory variables, working directory, and add the D4RL package
ENV HOME=/diffuser
WORKDIR $HOME
ADD D4RL $HOME/D4RL
ADD mujoco-py $HOME/mujoco-py
ADD mjkey.txt $HOME/mjkey.txt

#### single script creating the docker image  
RUN pip3 install -U Cython==3.0.0a10

RUN wget -c https://www.roboti.us/download/mujoco200_linux.zip -O mujoco200.zip
RUN unzip mujoco200.zip -d $HOME/.mujoco/
RUN rm mujoco200.zip
RUN mv $HOME/.mujoco/mujoco200_linux $HOME/.mujoco/mujoco200
RUN mv $HOME/mjkey.txt $HOME/.mujoco/mjkey.txt
ENV LD_LIBRARY_PATH=/diffuser/.mujoco/mujoco200/bin:${LD_LIBRARY_PATH}

WORKDIR $HOME/mujoco-py
RUN pip3 install --no-cache-dir -r requirements.txt
RUN pip3 install --no-cache-dir -r requirements.dev.txt
RUN python3 setup.py build 
RUN python3 setup.py install

WORKDIR $HOME/D4RL
RUN pip3 install -e .

WORKDIR $HOME
RUN pip3 install gym
#pip3 install mujoco_py==2.0.2.8
ADD requirements.txt $HOME/requirements.txt
RUN python3 -m pip install -r requirements.txt

### end of script
ENV MUJOCO_PY_MUJOCO_PATH=/diffuser/.mujoco/mujoco200

# extra command to build mujoco-py
ENV D4RL_SUPPRESS_IMPORT_ERROR=1
RUN python3 -c "import mujoco_py"
RUN python3 -c "import d4rl"
RUN echo 'set editing-mode vi' >> $HOME/.inputrc
RUN echo 'set keymap vi' >> $HOME/.inputrc

RUN echo "LD LIBRARY PATH: $LD_LIBRARY_PATH"
RUN echo "Python version: $(python --version)"

WORKDIR /diffuser/diffuser
# Sound Renderer For NeuralSound
Sound synthesis demo for SIGGRAPH 2022 Lab Session

## Running the precompiled binary
  
  ```bash
  cd build
  ./demo
  ```
  Use middle mouse button to rotate the camera.
  Use right mouse button to click the object to generate sound.
  Use the scroll wheel to zoom in and out.
  Press space to click last position (so you can click on unseen positions).
  Object and Material can be changed by list box in the left panel.

## Dependencies for build from source

```bash
# gcc, g++
sudo apt install gcc g++
# cuda 11.1 
wget https://developer.download.nvidia.com/compute/cuda/11.1.0/local_installers/cuda_11.1.0_455.23.05_linux.run
sudo sh cuda_11.1.0_455.23.05_linux.run # without driver if you have it installed
# glfw glew
sudo apt install libglfw3-dev libglew-dev
# cmake
wget https://github.com/Kitware/CMake/releases/download/v3.22.5/cmake-3.22.5-linux-x86_64.tar.gz
tar -xvf cmake-3.22.5-linux-x86_64.tar.gz
sudo cp -r cmake-3.22.5-linux-x86_64/ /usr/local/
# zlib
sudo apt install zlib1g-dev
# portaudio
sudo apt-get install libasound-dev
wget https://github.com/PortAudio/portaudio/archive/refs/tags/v19.7.0.tar.gz -O portaudio-19.7.0.tar.gz
tar -xvf portaudio-19.7.0.tar.gz
cd portaudio-19.7.0
cmake . -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/usr/local
make
sudo make install
```

add following to ~/.bashrc
```bash
export PATH=/usr/local/cuda-11.1/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda-11.1/lib64:$LD_LIBRARY_PATH
export PATH=/usr/local/cmake-3.22.5-linux-x86_64/bin:$PATH
export MESA_GL_VERSION_OVERRIDE=3.3
```




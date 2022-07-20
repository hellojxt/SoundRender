# Sound Renderer For NeuralSound


## build

### 1.build on Linux

#### Dependencies

- gcc, g++
```bash
sudo apt install gcc g++
```
- cuda 11.1 

显卡driver通过软件与更新-附加驱动-选择第一个安装
```bash
wget https://developer.download.nvidia.com/compute/cuda/11.1.0/local_installers/cuda_11.1.0_455.23.05_linux.run
sudo sh cuda_11.1.0_455.23.05_linux.run
```
重要：把driver一项去掉，否则可能出现图形界面崩溃的情况。
在~/.bashrc中添加以下内容：

```bash
export PATH=/usr/local/cuda-11.1/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda-11.1/lib64:$LD_LIBRARY_PATH
```
- glfw, glew
```bash
sudo apt install libglfw3-dev libglew-dev
```
- cmake
```bash
wget https://github.com/Kitware/CMake/releases/download/v3.22.5/cmake-3.22.5-linux-x86_64.tar.gz
tar -xvf cmake-3.22.5-linux-x86_64.tar.gz
sudo cp -r cmake-3.22.5-linux-x86_64/ /usr/local/
```
在~/.bashrc中添加以下内容：
```bash
export PATH=/usr/local/cmake-3.22.5-linux-x86_64/bin:$PATH
```
- opengl 3.3

经测试，需要在~/.bashrc中添加以下内容：
```bash
export MESA_GL_VERSION_OVERRIDE=3.3
```
- zlib

```bash
sudo apt install zlib1g
```

+ portaudio

```bash
sudo apt-get install libasound-dev

wget https://github.com/PortAudio/portaudio/archive/refs/tags/v19.7.0.tar.gz
tar -xvf portaudio-19.7.0.tar.gz
cd portaudio-19.7.0
cmake . -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/usr/local
make
sudo make install
```

- vscode
  官网安装，extension插件安装 C/C++ Extension Pack 即可



### 2.build on Windows

#### Dependencies

* Cmake GUI
* Visual Studio 2022

#### build:

* Open CMake GUI
* Add "SoundRender-main" as source directory. Add "/build" after this path as build directory
* Click "configure". Choose VS2022 as the generator 
* Click "generate". Open ".sln" file in the "build" directory. 


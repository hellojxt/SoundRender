# Sound Renderer For NeuralSound

### Dependencies
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
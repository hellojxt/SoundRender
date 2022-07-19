# 计算声音的流程

* 已有材料（asset中）：U矩阵（3n维方阵）、S矩阵（3n维方阵）、FFATMap。用户提供：外力f（3n*1的向量）、相机方位（给出FFAT需要用到的$r,\theta,\phi$）

```
这里的n是表面voxel的数量。
```

* S是一个对角阵，对角元素是特征值，记为$\lambda_i$，每个特征值对应一个“模态”。每一个模态对应的圆频率是 $\omega_i'$，有$\omega_i'=\omega_i\sqrt{1-\xi_i^2}$，其中$\omega_i=\sqrt{\lambda_i}$， $\xi_i=\frac{\alpha+\beta\lambda_i}{2\omega_i}$
```python
alpha,beta的参数根据材料选择，是有经验值的,在：
"NeuralSound\src\classic\fem\femModel.py"
class Material(object):
    # ρ E ν α β
    # 0 1 2 3 4
    Ceramic = 2700,7.2E10,0.19,6,1E-7
    Glass = 2600,6.2E10,0.20,1,1E-7
    Wood = 750,1.1E10,0.25,60,2E-6
    Plastic = 1070,1.4E9,0.35,30,1E-6
    Iron = 8000,2.1E11,0.28,5,1E-7
    Polycarbonate = 1190,2.4E9,0.37,0.5,4E-7
    Steel = 7850,2.0E11,0.29, 5 ,3E-8
    Tin = 7265, 5e10, 0.325, 2 ,3E-8

    ……
```

* 根据$f=\omega/2\pi$，得知每个模态的频率$f_i=\omega_i'/2\pi$，取在20Hz~20000Hz间的模态，只要这些。为了减少数量，可以取在这个范围内，最小的20个。因为人耳对低频更敏感，而且高频衰减快。有了这些频率，现在要计算每个频率对应的振幅：
* 根据公式$$p(\boldsymbol{x}, t)=\sum_{i}\left|p_{i}(\boldsymbol{x})\right| q_{i}(t)$$
这里的i是不同的模态。
* $\left|p_{i}(\boldsymbol{x})\right|$用FFAT图算，每个模态i对应一张。$\left|p_{i}(\boldsymbol{x})\right|=\frac{FFAT_i(\theta,\phi)}{r}$
* $q_{i}(t)=\int_{0}^{t} \frac{f_{i}(\tau)}{\omega_{i}^{\prime}} e^{-\xi_{i} \omega_{i}(t-\tau)} \sin \left(\omega_{i}^{\prime}(t-\tau)\right) \mathrm{d} \tau$，用数值方法做，就是：
$$q_{k}=2 \varepsilon \cos \theta q_{k-1}-\varepsilon^{2} q_{k-2}+\frac{2 f_{k-1}\left[\varepsilon \cos (\theta+\gamma)-\varepsilon^{2} \cos (2 \theta+\gamma)\right]}{3\omega \omega'}$$
* 其中，$\varepsilon=e^{-\xi \omega h}, \theta=\omega' h  ,\gamma=\arcsin \xi $，h为步长。需要注意的是，这里的q是单个模态i下的q，省略了下标i，对于其他变量也是同理省略了i。下标k表示时间，步长为h取决于硬件声卡，太大不准确，太小的话计算量大，而且比采样间隔还小就没有意义了。
* 这里的 $f_i$ 是 $U^T\boldsymbol{f}$ 这一个3n*1的列向量的第j个分量。如何确定j？就是前面那些符合条件的 $\lambda_i$ ,在S中对应的下标。如何确定$\boldsymbol{f}$？用户点击的那个mesh，所在的体素，在3n中占了其中的一个3，具体是哪一个？体素是否有编号？这个需要看一下程序。

* 总结来说，就是从一大堆特征值中找出符合条件的模态i，记录下其对应的特征值和特征向量。（特征向量们是U的一部分，之后算 $U^T\boldsymbol{f}$ 的时候，因为取的是i分量，所以不需要用到U的所有信息，有这部分特征向量的信息即可）。以后对于每个模态，在每一次采样上，算一个振幅：p的贡献用ffat算，q的贡献用数值积分算。然后合成声音就是在每一次采样，同时播放Ni（模态总数）个不同频率的声音，每个频率有它自己的振幅（贡献来自p、q两者）。
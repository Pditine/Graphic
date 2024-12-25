# 「风格化水体渲染」

## 获取水的深度

在现实生活中，水的深度是影响水的表现的极其重要的因素，根据我们的物理常识，水越深，光便越难穿透，其颜色表现也会更偏向深色，水也会表现得更加不透明。

<img src="https://hmxs-1315810738.cos.ap-shanghai.myqcloud.com/img/202412082334930.png" alt="image-20241208233435687" style="zoom: 50%;" />

如上图所示，海水的颜色随着水深的逐渐增加呈现除了极其明显的变化。

而在我们对于水体的渲染中，水深同样是极其重要的属性，那么我们应该如何在数字世界中得到水深呢？

### 在URP中拉取相机深度图



### 基于相机视线的深度

<img src="https://hmxs-1315810738.cos.ap-shanghai.myqcloud.com/img/202412090254588.png" alt="image-20241209025422513" style="zoom:50%;" />



![image-20241211011002876](https://hmxs-1315810738.cos.ap-shanghai.myqcloud.com/img/202412110110928.png)



```hlsl
/// Get the water depth relative to the camera.
half GetWaterDepthRelativeToCamera(float4 positionSS, float2 uvSS)
{
    half sceneDepth = SampleSceneDepth(uvSS); // based on DeclareDepthTexture.hlsl in URP
    half sceneDepthEye = LinearEyeDepth(sceneDepth, _ZBufferParams); // Sample the scene depth and convert it to linear eye depth.
    half scenePos = positionSS.w;
    half waterDepth = sceneDepthEye - scenePos; // waterDepth = SceneDepth - ScenePosition
    waterDepth = saturate(waterDepth * _WaterDepthFadeFactor); // Linearly interpolate(can be changed to other interpolation methods)
    return waterDepth;
}
```



<img src="https://hmxs-1315810738.cos.ap-shanghai.myqcloud.com/img/202412110025975.gif" alt="recording" style="zoom: 67%;" />



### 基于世界坐标的深度

<img src="https://hmxs-1315810738.cos.ap-shanghai.myqcloud.com/img/202412090255657.png" alt="image-20241209025556595" style="zoom:50%;" />



<img src="https://hmxs-1315810738.cos.ap-shanghai.myqcloud.com/img/202412090302839.png" alt="image-20241209030241779" style="zoom:50%;" />



<img src="https://hmxs-1315810738.cos.ap-shanghai.myqcloud.com/img/202412090236365.png" alt="image-20241209023639294" style="zoom:50%;" />



![image-20241211011137492](https://hmxs-1315810738.cos.ap-shanghai.myqcloud.com/img/202412110111589.png)



```hlsl
/// Get the water depth in WorldSpace.
half GetWaterDepthWorldSpace(float3 positionWS, float4 positionSS, float3 viewDirWS, float2 uvSS)
{
    half sceneDepth = SampleSceneDepth(uvSS); // based on DeclareDepthTexture.hlsl in URP
    half sceneDepthEye = LinearEyeDepth(sceneDepth, _ZBufferParams); // Sample the scene depth and convert it to linear eye depth.
    float3 scenePos = -viewDirWS / positionSS.w * sceneDepthEye + GetCameraPositionWS(); // Calculate the vector from the camera to the river bottom.
    half waterDepth = positionWS.y - scenePos.y; // waterDepth = River.y - RiverBottom.y
    waterDepth = 1 - saturate(exp(-waterDepth * _WaterDepthFadeFactor)); // Exponential interpolation(can be changed to other interpolation methods)
    return waterDepth;
}
```



<img src="https://hmxs-1315810738.cos.ap-shanghai.myqcloud.com/img/202412110027759.gif" alt="recording" style="zoom:67%;" />





## 着色

### 深度色

根据深度值进行深浅着色

直接使用Lerp

Gradient着色

Gradient控制脚本



<img src="https://hmxs-1315810738.cos.ap-shanghai.myqcloud.com/img/202412110106112.png" alt="image-20241211010645991" style="zoom:67%;" />



### 菲涅尔光



根据`HorizonDistance`与`HorizonColor`进行控制

<img src="https://hmxs-1315810738.cos.ap-shanghai.myqcloud.com/img/202412110108231.png" alt="image-20241211010809113" style="zoom: 67%;" />



### 水底颜色

基于水颜色的透明度

<img src="https://hmxs-1315810738.cos.ap-shanghai.myqcloud.com/img/202412110147709.png" alt="image-20241211014747565" style="zoom:67%;" />

### 色彩空间转换



## 折射

### 错位采样



<img src="https://hmxs-1315810738.cos.ap-shanghai.myqcloud.com/img/202412202004065.png" alt="image-20241220200412792" style="zoom: 50%;" />



### 伪影改善



<img src="https://hmxs-1315810738.cos.ap-shanghai.myqcloud.com/img/202412202002345.png" alt="image-20241220200229042" style="zoom:50%;" />



## 浮沫

### 表面浮沫

#### 纹理采样

#### UV扰动

<img src="https://hmxs-1315810738.cos.ap-shanghai.myqcloud.com/img/202412202357790.png" alt="image-20241220235735578" style="zoom: 67%;" />

### 边缘浮沫

#### 对深度的再利用

#### 采样噪声图



<img src="https://hmxs-1315810738.cos.ap-shanghai.myqcloud.com/img/202412210203419.png" alt="image-20241221020311238" style="zoom: 67%;" />

## 光照

### 采样法线贴图

光照计算离不开法线，而游戏中我们的水面实际上就是一个Plane，其网格上并没有丰富的可供计算的法线信息，但我们可以通过法线贴图来模拟水体的法线。

// TODO : 法线贴图

通过Shader Graph中的Sample Texture 2D节点我们可以很方便地采样法线贴图，然后我们可以通过Normal Strength来控制法线的强度。

但因为我们只有一张法线贴图，而水体往往是在不停运动的，简单的采样我们只能得到一个静态的法线，这显然是不够的，我们需要通过一些技巧来模拟水体的动态法线。

这里我们使用了两次采样来实现动态法线的效果，通过让两次采样的UV稍微错开，然后对两次采样的结果进行插值，我们可以得到一个动态的法线效果。

// TODO : GIF

### 光照计算

在得到了法线之后，计算光照就变得相对简单了，这里使用了自行编写的HLSL函数配合Custom Function节点来实现光照的计算。

在光照模型上，选择了经典的Blinn-Phong模型。

```hlsl

```

## 波浪

### Gerstner波

### 应用波浪

## 浮力模拟

既然有波浪了，那么根据物理规律，水上的物体应该会受到波浪的影响，如果不模拟浮力的话，一些水上物体的表现便会显得很不真实。如下面的GIF所示。

// TODO : GIF

水上的浮萍应该会随着波浪的起伏而上下浮动，而不是僵硬地静止在水面上。

但问题在于，物体所受浮力应该与动态变化的波浪相关，但目前的波浪是在GPU端计算的，而Unity的物理引擎是在CPU端计算的。

而这里我们采用的方法是在CPU中编写一个和GPU中波浪计算相同的函数，并同步二者的参数，这样我们就可以得到波浪的信息了。

```c#

```



## 水面反射



## 参考

[💧Stylized Water Shader](https://ameye.dev/notes/stylized-water-shader/)

[Unity URP 风格化水](http://chenglixue.top/?p=45#toc-head-3)

[Catlike Coding](https://catlikecoding.com/unity/tutorials/flow/)

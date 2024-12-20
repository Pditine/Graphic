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



```glsl
/// hlsl
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



```glsl
/// hlsl
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

![image-20241211003223611](https://hmxs-1315810738.cos.ap-shanghai.myqcloud.com/img/202412110032680.png)

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



## 参考

[💧Stylized Water Shader](https://ameye.dev/notes/stylized-water-shader/)

[Unity URP 风格化水](http://chenglixue.top/?p=45#toc-head-3)
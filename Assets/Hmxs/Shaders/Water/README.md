# 「风格化水体渲染」

## 获取水的深度

在现实生活中，水的深度是影响水的表现的极其重要的因素，根据我们的物理常识，水越深，光便越难穿透，其颜色表现也会更偏向深色，水也会表现得更加不透明。

<img src="https://hmxs-1315810738.cos.ap-shanghai.myqcloud.com/img/202412082334930.png" alt="image-20241208233435687" style="zoom: 50%;" />

如上图所示，海水的颜色随着水深的逐渐增加呈现除了极其明显的变化。

而在我们对于水体的渲染中，水深同样是极其重要的属性，那么我们应该如何在数字世界中得到水深呢？

### 基于相机视线的深度

<img src="https://hmxs-1315810738.cos.ap-shanghai.myqcloud.com/img/202412090254588.png" alt="image-20241209025422513" style="zoom:50%;" />



<img src="https://hmxs-1315810738.cos.ap-shanghai.myqcloud.com/img/202412082340222.gif" alt="recording" style="zoom: 33%;" />



### 基于世界坐标的深度

<img src="https://hmxs-1315810738.cos.ap-shanghai.myqcloud.com/img/202412090255657.png" alt="image-20241209025556595" style="zoom:50%;" />



<img src="https://hmxs-1315810738.cos.ap-shanghai.myqcloud.com/img/202412090302839.png" alt="image-20241209030241779" style="zoom:50%;" />



<img src="https://hmxs-1315810738.cos.ap-shanghai.myqcloud.com/img/202412090236365.png" alt="image-20241209023639294" style="zoom:50%;" />



<img src="https://hmxs-1315810738.cos.ap-shanghai.myqcloud.com/img/202412090324531.gif" alt="recording" style="zoom: 33%;" />

## 着色

### 深度着色






## 参考

[💧Stylized Water Shader](https://ameye.dev/notes/stylized-water-shader/)
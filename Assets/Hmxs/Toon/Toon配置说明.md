# Toon配置说明

![image-20241227102219758](https://hmxs-1315810738.cos.ap-shanghai.myqcloud.com/img/202412271022862.png)

两个材质的唯一区别就是一个有描边一个没有

<img src="https://hmxs-1315810738.cos.ap-shanghai.myqcloud.com/img/202412271023651.png" alt="image-20241227102329605" style="zoom:50%;" />

配置项方面，有两个需要特别注意`DiffuseRamp`与描边，其他都比较常规

## Diffuse Ramp

工作方式类似水体渲染的Gradient，但是其不会直接决定颜色，而是决定了着色深浅

同样需要借助工具类`ToonManager`将Gradient转化为Texture进行使用

在Prefabs文件夹下可以找到`ToonManager`的预制体

将其拖到场景中，拖入要更改的材质，然后更改Gradient，就能实时看到效果了

调整完毕记得点击Inspector中的SAVE按钮

## 描边

所有需要描边的物体的网格都需要特殊处理，否则描边表现会很奇怪

<img src="https://hmxs-1315810738.cos.ap-shanghai.myqcloud.com/img/202412271028686.png" alt="image-20241227102807641" style="zoom:67%;" />

在这里可以找到我编写的工具类，点开后如下图所示

<img src="https://hmxs-1315810738.cos.ap-shanghai.myqcloud.com/img/202412271028346.png" alt="image-20241227102842284" style="zoom:50%;" />

在`EnableSeleted`被勾选时，直接点击场景或是工程中的物体，工具类会自动将点击的物体的Mesh加入列表中

`Channel`保持在UV4不要改动，`CreateNewMesh`最好也一直勾着吧

然后选择保存的文件夹，点击Smooth即会在文件夹中生成新的调整过的Mesh

之后将调整过的Mesh挂回物体上，就可以使用描边了

![image-20241227103220853](https://hmxs-1315810738.cos.ap-shanghai.myqcloud.com/img/202412271032916.png)

调整后的Mesh如上图所示

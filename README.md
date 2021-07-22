# nobugCPU

## 基于Altera CPM7128的硬连线控制器设计

按照给定数据格式、指令系统和数据通路，根据所提供的器件要求，自行设计一个基于硬布线控制器的顺序模型处理机。

- 基本功能：根据设计方案，在TEC-8上进行组装、调试运行
- 附加功能：
    - 在原指令基础上要求扩指至少三条
    - 修改PC指针功能（任意指针）

两种实现方式分别见[nobugCPU-behave.vhd](./nobugCPU-behave.vhd)和[nobugCPU-nopipe.vhd](./nobugCPU-nopipe.vhd)。

### 自选题目一

在必选题目基础上，完成流水硬连线控制器的设计。根据设计方案，在TEC-8上进行组装、调试运行。

流水线的实现见[nobugCPU-pipe.vhd](./nobugCPU-pipe.vhd)。

### 自选题目二

在必选题目基础上，设计实现带有中断功能的硬布线控制器。

中断的实现见[nobugCPU-interrupt.vhd](./nobugCPU-interrupt.vhd)。

## 合作者

[@xqmmcqs](https://github.com/xqmmcqs)

[@buptsg2019](https://github.com/buptsg2019)

[@twinkle](https://gitee.com/twinkle2019ly)

[@zhao-yuteng](https://gitee.com/zhao-yuteng)


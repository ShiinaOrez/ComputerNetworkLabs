# Lab 4: Using NS

[TOC]

## 实验过程

+ 编写tcl脚本
+ 使用ns运行tcl脚本模拟网络，并利用nam生成动画
+ 解析上一步产生的trace数据，计算丢包率
+ 使用解析后的数据画图
+ 分析原理

## 实验环境

> Linux Ubuntu 18.04 with bash

### 安装依赖

> sudo apt-get install ns2 (ns)
> sudo apt-get install tcl (tclsh)
> sudo apt-get install nam (nam)
> sudo apt-get install original-awk (awk)
> sudo apt-get install gnuplot-qt

## 开始实验
### 编写tcl脚本

```tcl
set ns [new Simulator]

#open a nam trace file
set nf [open out.nam w]
$ns namtrace-all $nf

#open a trace file
set tf [open out.tr w]
$ns trace-all $tf

#finish procedure
proc finish {} {
 global ns nf tf
 $ns flush-trace
 close $nf
 close $tf
 exec nam out.nam &
 exit 0
}

#create nodes
set node(http) [$ns node]
set node(rtp) [$ns node]
set node(recv) [$ns node]

#create links
$ns duplex-link $node(http) $node(recv) 0.9Mb 10ms DropTail
$ns duplex-link $node(rtp) $node(recv) 0.9Mb 10ms DropTail

#set queue size
$ns queue-limit $node(http) $node(recv) 10
$ns queue-limit $node(rtp) $node(recv) 10

#relayout nodes
$ns duplex-link-op $node(http) $node(recv) orient right-down
$ns duplex-link-op $node(rtp) $node(recv) orient right-up

#set colors
$ns color 1 blue
$ns color 2 red

#set a tcp connection
set tcp [new Agent/TCP]
$ns attach-agent $node(http) $tcp
set sink [new Agent/TCPSink]
$ns attach-agent $node(recv) $sink
$ns connect $tcp $sink
$tcp set fid_ 1

#set a cbr above tcp connection
set cbr(http) [new Application/Traffic/CBR]
$cbr(http) attach-agent $tcp
$cbr(http) set type_ CBR
$cbr(http) set packet_size_ 1000
$cbr(http) set rate_ 1mb
$cbr(http) set random_ false

#set a rtp connection
set rtp [new Agent/UDP]
$ns attach-agent $node(rtp) $rtp
set null [new Agent/Null]
$ns attach-agent $node(recv) $null
$ns connect $rtp $null
$rtp set fid_ 2

#set a cbr above tcp connection
set cbr(rtp) [new Application/Traffic/CBR]
$cbr(rtp) attach-agent $rtp
$cbr(rtp) set type_ CBR
$cbr(rtp) set packet_size_ 1000
$cbr(rtp) set rate_ 1mb
$cbr(rtp) set random_ false

#schedule
$ns at 0.1 "$cbr(http) start"
$ns at 0.1 "$cbr(rtp) start"
$ns at 4.0 "$cbr(http) stop"
$ns at 4.0 "$cbr(rtp) stop"
$ns at 4.1 "finish"

$ns run
```
编写截图↓
[![2019-06-04 09-19-38 的屏幕截图.png](https://i.loli.net/2019/06/04/5cf5c77f274b978774.png)](https://i.loli.net/2019/06/04/5cf5c77f274b978774.png)

tcl脚本是基于tclsh的，其实也可以理解为普通的sh脚本，目的是省去大量的bash输入，避免手误的错误产生等等，这里使用了tcp和udp两个协议。

### 运行tcl脚本

在命令行中输入以下命令：

```sh
ns your_file_name.tcl
```
运行结束后会产生一个out.tr文件和一个nam动画，用来演示模拟过程，但是这个动画太快了我们确实看不出什么，因此需要分析数据进行画图。

运行截图↓
[![2019-06-04 09-24-32 的屏幕截图.png](https://i.loli.net/2019/06/04/5cf5c863a776270992.png)](https://i.loli.net/2019/06/04/5cf5c863a776270992.png)

### 解析trace数据，计算丢包率

使用awk语言来对数据进行处理：

```awk
BEGIN {
 tcp_droped = 0;
 udp_droped = 0;
 last_tcp = -1;
 last_udp = -1;
 total_tcp = 0;
 total_udp = 0;
 i = 0;
}

{
 action = $1;
 time = $2;
 type = $5;
 seq_no = $11;

 if(action == "+" && type == "tcp"){
  total_tcp = total_tcp + 1;
 }

 if(action == "+" && type == "cbr"){
  total_udp = total_udp + 1;
 }

 if(action=="r"){
  if(type=="tcp"){
   if(seq_no != last_tcp + 1){
    tcp_droped = tcp_droped + 1;
   }
   last_tcp = seq_no;
  }

  if(type=="cbr"){
   if(seq_no != last_udp + 1){
    udp_droped = udp_droped + 1;
   }
   last_udp = seq_no;
  }

  time_point[i] = time;
  if(total_tcp > 0)
   tcp_loss[i] = tcp_droped / total_tcp * 100;
  else
   tcp_loss[i] = 0;
  if(total_udp > 0)
   udp_loss[i] = udp_droped / total_udp * 100;
  else
   udp_loss[i] = 0;
  i = i + 1;
  
 }
 
}

END {
 printf("%.2f\t%.2f\t%.2f\n",0,0,0);

 for(j=0; j<i; j++){
  printf("%.2f\t%.2f\t%.2f\n",time_point[j], tcp_loss[j], udp_loss[j]);
 }
}
```

awk这个小众到sublime都不支持高亮...

使用awk进行分析的话，需要按照以下命令执行：

```sh
awk -f your_awk.awk your_trace.tr > out.txt
```

然后你就会得到类似于这样的效果↓

[![2019-06-04 09-34-03 的屏幕截图.png](https://i.loli.net/2019/06/04/5cf5ca9949c8942672.png)](https://i.loli.net/2019/06/04/5cf5ca9949c8942672.png)

### 使用解析后的数据画图

画图的方式其实是多种多样的，比如使用pyplot，但是这里使用gnuplot-qt来画图

gnuplot是使用bash的形式来解析和绘图，基本的使用方式可以自行google

在命令行输入
```sh
gnuplot
```
来进入gnuplot的bash模式：

输入：

```gnuplot
plot "http_rtp.txt" using 2, "http_rtp.txt" using 3
```

[![2019-06-04 10-08-02 的屏幕截图.png](https://i.loli.net/2019/06/04/5cf5d294c0c3b75707.png)](https://i.loli.net/2019/06/04/5cf5d294c0c3b75707.png)

然后就会显示如上图的图像。

### 分析原理

+ 当链路带宽设为1Mb，TCP和UDP速率都为1000时，TCP有丢包现象，UDP没有丢包现象，这大概是因为TCP是面向连接的协议，而UDP并不是。当把链路带宽都设定为0.9Mb，tcp和udp都有严重的丢包现象。可见虽然TCP有重传机制，但在带宽太低的情况下，仍然会丢包。

+ 最终的曲线图说明，TCP的拥塞控制机制发挥了作用，丢包率逐步下降。而UDP没有拥塞控制机制，当缓冲队列满后，丢包率迅速上升。
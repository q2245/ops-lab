# Linux 与网络基础

## 启动练习容器

```bash
make up PROFILE=linux
docker exec -it ops-lab-toolbox-1 bash
```

`netshoot` 镜像预装了网络排障全套工具，是练习的首选。

## 需要掌握的命令

### 进程与系统

```bash
ps aux
top
vmstat 1
iostat -x 1
df -h
free -m
```

### 网络

```bash
ip addr
ip route
ss -tunlp
dig example.com
ping 8.8.8.8
traceroute 8.8.8.8
tcpdump -i any port 80
```

## 动手练习

1. 在 toolbox 里 `tcpdump -i any port 80 -w /tmp/a.pcap`，同时另一个终端访问 `http://localhost:18080/`，然后用 `tcpdump -r /tmp/a.pcap -nn` 读包。
2. 用 `ss -tunlp | grep 8080` 确认端口监听，理解 LISTEN 和 ESTABLISHED 的区别。
3. 用 `dig +trace google.com` 完整跟踪一次 DNS 解析过程。
4. 用 `curl -v http://localhost:18080/` 观察 TCP 三次握手、HTTP 请求头、响应码。

## 关键概念

- **进程 vs 线程**：进程是资源分配单位，线程是调度单位。Redis 单线程快是因为纯内存 + IO 多路复用，不是因为线程少。
- **文件描述符**：Linux 一切皆文件，`ulimit -n` 决定能开多少连接，高并发服务经常在这里翻车。
- **TIME_WAIT**：主动关闭方进入的状态，大量短连接时会出现，对应 `net.ipv4.tcp_tw_reuse`。

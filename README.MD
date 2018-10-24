ZUA 示例和测试工程
本EXE在WIN10上X64 Debug编译，由于是面向开发者，暂未提供Windows Release版本。

详情参见  <a href="https://github.com/ymwang78/zua/wiki"> Wiki </a>。

<h1> Windows </h1> 

运行方法：

1. 因为是DEBUG，需要VisualStudio 2017 debug运行时，最简单的办法直接安装Visual Studio 2017 Community版

2. 双击执行start_server.bat 或者

   CD zua.exe所在目录，执行 zua.exe --console

<h1> Centos7 x64 Linux  </h1>

1. Linux依赖库(Centos 7)：

    rpm -ivh  http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

    rpm -ivh https://download.postgresql.org/pub/repos/yum/9.4/redhat/rhel-7-x86_64/pgdg-centos94-9.4-3.noarch.rpm
    
    yum install postgresql94-libs boost hiredis gperftools-libs mariadb-libs
    
2. 程序 Linux 下载:

    http://dist.zhidu.biz/vxserver/c7testing/

3. 运行

    wget http://dist.zhidu.biz/vxserver/c7testing/zua.2.7.xxxxxxxxxxxxxx.bin
    
    chmod +x *.bin
    
    ./zua.2.7.xxxxxxxxxxxxxx.bin
    
    cd /opt/zua
    
    mv zua.xml.tpl zua.xml
    
    ./zua --console  (运行在控制台) 或者 /etc/init.d/zua restart (以damon服务跑，会多一个监视进程)



ZUA是ZCE的lua相关功能在服务端的一个实现，把ZCE的系统能力通过LUA接口提供出来。

ZUA 示例和测试工程

本EXE在WIN10上X64 Release编译。

详情参见  <a href="https://github.com/ymwang78/zua/wiki"> Wiki </a>。

<h1> Windows </h1> 

运行方法：

1. 需要VisualStudio 2017 Release运行时请自行下载安装。

2. 双击执行start_server.bat 或者

   CD zua.exe所在目录，执行 zua.exe --console

<h1> Centos7 x64 Linux  </h1>

1. Linux依赖库(Centos 7)：

    rpm -ivh  http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

    rpm -ivh https://download.postgresql.org/pub/repos/yum/11/redhat/rhel-7-x86_64/pgdg-centos11-11-2.noarch.rpm
    
    yum install postgresql11-libs boost hiredis gperftools-libs mariadb-libs
    
2. 程序 Linux 下载:

    http://dist.zhidu.biz/vxserver/c7testing/

3. 运行

    wget http://dist.zhidu.biz/vxserver/c7testing/zua.2.7.xxxxxxxxxxxxxx.bin
    
    chmod +x *.bin
    
    ./zua.2.7.xxxxxxxxxxxxxx.bin
    
    cd /opt/zua
    
    mv zua.xml.tpl zua.xml
    
    ./zua --console  (运行在控制台) 或者 /etc/init.d/zua restart (以damon服务跑，会多一个监视进程)



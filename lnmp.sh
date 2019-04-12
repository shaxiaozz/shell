#!/bin/bash
#Author: zeng
#Time: 2019/3/20
#Version: 2.1.5
#System: CentOS7+
#描述：一键编译安装LNMP，nginx1.14.0，MYSQL5.6.17，PHP7.2.6。

NEWTIME=`date +%s`
CPUS=`lscpu | grep "^CPU(s)" | awk '{print $NF}'`
#脚本说明
echo -e "\033[32m一键编译安装LNMP,分为六个大步骤\033[0m"
echo "1,配置阿里云网络源，epel源及，安装编译环境"
echo "2,编译安装cmake3.14"
echo "3,编译安装nginx1.14.0"
echo "4,编译安装MYSQL5.6.17"
echo "5,编译安装PHP7.1.27"
echo "6,最后说明"
echo ""

#前提检测
if [ ! $UID -eq 0 ];then
   echo "请使用拥有管理员权限的用户来执行该脚本..."
   echo "Quiting...."
   exit 1
fi

if ! ping -c 4 www.baidu.com &> /dev/null;then
   echo "请调试你的网络，该脚本需可达外网..."
   echo "Quiting...."
   exit 2
fi

if [ ! -d ~/src ];then
   echo "请创建~/src目录，并把源码包存放于此处..."
   echo "Quiting...."
   exit 3
fi

if [ ! -d /usr/local/src ];then
   echo "请创建/usr/local/src目录，该目录用于存放解压后的源码文件..."
   echo "Quiting...."
   exit 4
fi

if [ ! -e ~/src/mysql-5.6.17.tar.gz -a ! -e ~/src/nginx-1.14.0.tar.gz -a ! -e ~/src/php-7.1.27.tar.gz -a ! -e ~/src/pcre-8.42.zip -a ! -e ~/src/cmake-3.14.0.tar.gz ];then
   echo "请在~/src目录下存放源码包:源码包列表如下：
mysql-5.6.17.tar.gz
nginx-1.14.0.tar.gz
pcre-8.42.zip
php-7.1.27.tar.gz
cmake-3.14.0.tar.gz"
   echo "源码包pcre-8.42.zip为nginx的依赖库"
   echo "Quiting...."
   exit 5
fi

#1,配置阿里云网络网络源及安装编译环境
mv -f /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bakk
echo "[aliyun]
name=aliyun
baseurl=https://mirrors.aliyun.com/centos/7/os/x86_64/
gpgcheck=0
enable=1" > /etc/yum.repos.d/aliyun.repo
echo "[epel]
name=aliyun
baseurl=https://mirrors.aliyun.com/epel/7/x86_64/
gpgcheck=0
enable=1" > /etc/yum.repos.d/epel.repo
yum repolist
yum -y install gcc gcc-c++ 2> /tmp/lnmp.log || exit 7

#2,编译安装cmake3.14
if [ -d /usr/local/src/cmake-3.14.0 ];then
   rm -rf /usr/local/src/cmake-3.14.0 &> /dev/null
   tar -xf ~/src/cmake-3.14.0.tar.gz -C /usr/local/src/
else
   tar -xf ~/src/cmake-3.14.0.tar.gz -C /usr/local/src/
fi
cd /usr/local/src/cmake-3.14.0/
./configure --prefix=/usr/local/cmake 2> /tmp/lnmp.log || exit 8
gmake -j $CPUS
gmake install
echo 'PATH=/usr/local/cmake/bin:$PATH' >> /etc/profile
source /etc/profile
echo "编译安装cmake完成..."

#3,编译安装nginx1.14.0
yum -y install openssl openssl-devel unzip 2> /tmp/lnmp.log || exit 9
groupadd -r nginx
useradd -M -g nginx -s /sbin/nologin nginx
if [ -d /usr/local/src/pcre-8.42 ];then
   rm -rf /usr/local/src/pcre-8.42
   unzip ~/src/pcre-8.42.zip -d /usr/local/src/ &> /dev/null
   echo "解压nginx依赖库pcre.8.42完成..."
else
   unzip ~/src/pcre-8.42.zip -d /usr/local/src/
   echo "解压nginx依赖库pcre.8.42完成..."
fi
if [ -d /usr/local/nginx-1.14.0 ];then
   rm -rf /usr/local/nginx-1.14.0 &> /dev/null
   tar -xf ~/src/nginx-1.14.0.tar.gz -C /usr/local/src/
   echo "解压nginx源码包完成"
else
   tar -xf ~/src/nginx-1.14.0.tar.gz -C /usr/local/src/
   echo "解压nginx源码包完成"
fi
cd /usr/local/src/nginx-1.14.0/
echo '--prefix=/usr/local/nginx --with-http_dav_module --with-http_stub_status_module --with-http_addition_module --with-http_sub_module --with-http_flv_module --with-http_mp4_module --with-http_ssl_module --user=nginx --group=nginx --with-pcre=/usr/local/src/pcre-8.42/' | ./configure 2> /tmp/lnmp.log || exit 10
make -j $CPUS
make install
sed -i "s/#user  nobody/user  nginx nginx/" /usr/local/nginx/conf/nginx.conf
sed -i 's/index  index.html index.htm;/index  index.php index.html index.htm;/' /usr/local/nginx/conf/nginx.conf
STRING=`echo 'location ~ \.php$ {
root           html;
fastcgi_pass   127.0.0.1:9000;
fastcgi_index  index.php;
fastcgi_param  SCRIPT_FILENAME  /usr/local/nginx/html$fastcgi_script_name;
include        fastcgi_params;
}'`
sed -i "78a `echo $STRING`" /usr/local/nginx/conf/nginx.conf
echo 'export PATH=$PATH:/usr/local/nginx/sbin' >> /etc/profile
source /etc/profile
nginx -t && nginx && echo "启动nginx服务成功...."
if service firewalld status &> /dev/null;then
   firewall-cmd --permanent --add-port=80/tcp
   firewall-cmd --reload
else
   echo "\033[31mFirewalld not running....\033[0m" 
fi

#4,编译安装MYSQL5.6.17
yum -y remove mariadb* boost-*
yum -y install ncurses-devel perl 'perl(Data::Dumper)' wget 2> /tmp/lnmp.log || exit 11
groupadd mysql
useradd -M -s /sbin/nologin -g mysql mysql
mkdir -p /usr/local/mysql/data
if [ -d /usr/local/src/mysql-5.6.17/ ];then
   rm -rf /usr/local/src/mysql-5.6.17/ &> /dev/null
   tar -xf ~/src/mysql-5.6.17.tar.gz -C /usr/local/src/
else
   tar -xf ~/src/mysql-5.6.17.tar.gz -C /usr/local/src/
fi
cd /usr/local/src/mysql-5.6.17/
cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DMYSQL_UNIX_ADDR=/usr/local/mysql/mysql.sock -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_ARCHIVE_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DMYSQL_DATADIR=/usr/local/mysql/data -DMYSQL_TCP_PORT=3306 -DENABLE_DOWNLOADS=1 2> /tmp/lnmp.log || exit 12
rm -rf CMakeCache.txt
make -j $CPUS
make install
chown -R mysql:mysql /usr/local/mysql
cd /usr/local/mysql/
scripts/mysql_install_db --user=mysql --datadir=/usr/local/mysql/data
\cp -f /usr/local/mysql/support-files/my-default.cnf /etc/my.cnf
\cp -f support-files/mysql.server /etc/init.d/mysqld
sed -i 's@# basedir = .....@  basedir=/usr/local/mysql@' /etc/my.cnf
sed -i 's@# datadir = .....@  datadir=/usr/local/mysql/data@' /etc/my.cnf
sed -i 's@# port = .....@  port = 3306@' /etc/my.cnf
sed -i 's@# server_id = .....@  server_id = 136@' /etc/my.cnf
echo 'export PATH=$PATH:/usr/local/mysql/bin' >> /etc/profile
source /etc/profile
service mysqld start
mysqladmin -u root password password
if service firewalld status &> /dev/null;then
   firewall-cmd --permanent --add-port=3306/tcp
   firewall-cmd --reload
else
   echo "\033[31mFirewalld not running....\033[0m" 
fi

#5,编译安装PHP7.1
yum -y install php-mcrypt libmcrypt libmcrypt-devel pcre* autoconf freetype gd libmcrypt libpng libpng-devel libjpeg libxml2 libxml2-devel zlib curl curl-devel re2c net-snmp-devel libjpeg-devel php-ldap openldap-devel openldap-servers openldap-clients freetype-devel gmp-devel 2> /tmp/lnmp.log || exit 13
groupadd php
useradd -M -s /sbin/nologin	-g php php
tar -xf ~/src/php-7.1.27.tar.gz -C /usr/local/src/
cd /usr/local/src/php-7.1.27
./configure --prefix=/usr/local/php \
--with-config-file-path=/usr/local/php/etc \
--with-fpm-user=php --with-fpm-group=php \
--enable-fpm \
--with-mysqli=mysqlnd 2> /tmp/lnmp.log || exit 14
make -j $CPUS
make install
\cp /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.conf
\cp /usr/local/src/php-7.1.27/php.ini-production /usr/local/php/etc/php.ini
\cp /usr/local/src/php-7.1.27/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
chmod +x /etc/init.d/php-fpm
echo '<?php phpinfo() ?>' > /usr/local/nginx/html/index.php
/etc/init.d/php-fpm start && echo "启动php-fpm服务成功...."
if service firewalld status &> /dev/null;then
   firewall-cmd --permanent --add-port=9000/tcp
   firewall-cmd --reload
else
   echo "\033[31mFirewalld not running....\033[0m" 
fi

#6，最后说明
echo ""
echo "脚本运行完毕！"
echo "1，编译安装LNMP完成"
echo "2,cmkae，nginx，mysql，php的安装目录分别为：
cmake /usr/local/cmake
nginx /usr/local/nginx
mysql /usr/local/nginx 数据库目录: /usr/local/mysql/data
php /usr/local/php"
echo "3，测试nginx是否可解析php文件,请访问 http://IP/index.php"
echo “4，如果你是运行我这脚本后无法搭建成功的，请联系我：QQ2309108459，我将无偿为你服务....”
echo "谢谢！！！！"
echo ""
USTIME=$[$[`date +%s`-$NEWTIME]%60]
echo -e "\033[32m脚本执行完毕，耗时:${USTIME}分钟\033[0m"
exit 0

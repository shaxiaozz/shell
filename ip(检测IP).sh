#!/bin/bash
#
#使用for循环测试当前网段中所有的主机是否在线

#脚本说明
echo "本脚本用于检查当前系统所在网段的所有主机是否在线。"
echo ""

#取出当前系统的IP，及网段
read -p "请输入你的网卡名称：" NETWORKNAME

if [ ! -e /etc/sysconfig/network-scripts/ifcfg-${NETWORKNAME} ];then
	echo "No such network card."
	exit 1
fi

NOWIP=`ip add show $NETWORKNAME | head -3 | tail -1 | awk ' {print $2}' | awk -F/ '{print $1}'`                                                                        #取出当前系统的IP地址
HOST=`echo $NOWIP | awk -F. '{print $NF}'`        #取出当前系统IP的主机号
NETWORK=`echo $NOWIP | sed "s/"${HOST}"//"`       #已取出网段信息
echo "Your IP is $NOWIP."
echo "Your Network is ${NETWORK}0"
echo ""

#交互式操作
read -p "请输入需要查询的状态: up/done " OPTIONS
echo "进行检查中...."
echo ""

#进行测试
if [ $OPTIONS == 'up' ];then
	for I in `seq 1 255`;do
		IP=${NETWORK}$I
		if ping -c 1 -w 1 $IP &> /dev/null;then
			echo -e "\033[32m $IP is up. \033[0m"
		fi
	done
elif [ $OPTIONS == 'done' ];then
	for I in `seq 1 255`;do
		IP=${NETWORK}$I
		if ! ping -c 1 -w 1 $IP &> /dev/null;then
			echo -e "\033[31m $IP is done. \033[0m"
		fi
	done
else
	echo "Unknown,options."
	echo "Usage: [up/done]"
	exit 1
fi

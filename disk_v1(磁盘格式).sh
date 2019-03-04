#!/bin/bash
#
#脚本完成磁盘分区格式化

#取出当前系统存在的磁盘列表
echo -e "\033[32m磁盘分区格式化脚本 V1\033[0m"
echo -e "\033[31m警告：接下来的操作可能会损坏数据，请谨慎选择\033[0m"
echo "以下为当前系统存在的磁盘列表"
fdisk -l 2> /dev/null | grep -o "Disk /dev/[sh]d[a-z]"

#提供用户选择，quit为提出脚本
read -p "请输入你的选择：" XUANZE
if [ $XUANZE == 'quit' ];then
	echo "Quiting...."
	exit 1
fi

#当用户选择错误，则重新选择
until fdisk -l 2> /dev/null | grep -w "Disk $XUANZE" &> /dev/null;do
	read -p "选择错误，请重新输入你的选择：" XUANZE
done
	
#当用户选择完成后
read -p "接下来的操作可能会损坏数据，是否继续：" YN

until [ $YN == 'y' -o $YN == 'n' ];do
	read -p "选择错误，请重新输入你的选择：" YN
done

#进行判断Y/N
if [ $YN == 'n' ];then
	echo "Quiting...."
	exit 2
else
	echo -e "\033[32m正在抹除${XUANZE}设备数据....\033[0m"
	[ dd if=/dev/zero of=$XUANZE bs=512 count=1 &> /dev/null -eq 0 ] && echo "抹除数据成功,下面进行分区"
	sync
	sleep 3
	echo "n
p
1

+20M
n
p
2

+512M
n
p
3

+128M
t
3
82" | fdisk $XUANZE &> /dev/null
	echo "分区完成，正在查看分区列表:"
	fdisk -l | grep "/dev/sdb"
	echo "对分区进行格式化文件系统"
	sync
	sleep 2
	mkfs.xfs ${XUANZE}1 &> /dev/null
	mkfs.xfs ${XUANZE}2 &> /dev/null
	mkfs.swap ${XUANZE}3 &> /dev/null
	echo "文件系统格式化完成，脚本到此结束！"
fi


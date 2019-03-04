#!/bin/bash
#
#一键格式化硬盘及分区。第一个主分区20M,第二个主分区512M，第三个主分区128M，并且第三个分区的类型为swap

echo -e "\033[32m 一键磁盘分区 v2\033[0m"
echo -e "\033[31m 警告：接下来的操作可能会损坏磁盘数据\033[0m"
echo "以下为当前系统存在的硬盘："
fdisk -l 2> /dev/null | grep -o "Disk /dev/[sh]d[a-z]"

read -p "请输入你的选择：" XUANZE

if [ $XUANZE == 'quit' ];then
	echo "Quiting..."
	exit 1
fi

until fdisk -l 2> /dev/null | grep -w "Disk $XUANZE" &> /dev/null;do
	read -p "选择错误，请重新输入你的选择：" XUANZE
done

read -p "接下来的操作可能会损坏数据，是否继续：" YN

until [ $YN == 'y' -o $YN == 'n' ];do
	read -p "选择错误，请重新输入你的选择：" YN
done

if [ $YN == 'n' ];then
	echo "Quiting..."
	exit 2
else
	if df | grep "$XUANZE" &> /dev/null;then
		read -p "当前磁盘上的分区已经被挂载，是否取消挂载并格式化硬盘：" YESNO
		if [ $YESNO == 'y' ];then
			umount `df | grep "$XUANZE" | awk ' {print $NF}'`
			echo "已取消挂载，下面进行初始化硬盘:"
			dd if=/dev/zero of=$XUANZE bs=512 count=1 &> /dev/null
			echo "初始化 $XUANZE 硬盘完成。下面进行分区："
		else
			echo "Quiting..."
			exit 3
		fi
	else
		dd if=/dev/zero of=$XUANZE bs=512 count=1 &> /dev/null
		echo "初始化 $XUANZE 硬盘完成。下面进行分区："
	fi
	sync
	sleep 3
	echo 'n
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
82
w' | fdisk $XUANZE &> /dev/null
	echo "分区创建完成：下面进行格式化文件系统。"
	sleep 2
	mkfs.xfs ${XUANZE}1 &> /dev/null
	mkfs.xfs ${XUANZE}2 &> /dev/null
	mkswap ${XUANZE}3 &> /dev/null
	echo "格式化文件系统完成。"
	echo "${XUANZE}1 is xfs."
	echo "${XUANZE}2 is xfs."
	echo "${XUANZE}3 is swap."
	
fi
	
	
	

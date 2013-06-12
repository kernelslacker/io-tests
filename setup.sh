#!/bin/sh
#
# Storage/fs tests.
#
# Done:
# - RAID0/1/5
# - EXT4, XFS, BTRFS
#
# TODO:
#  - RAID6/RAID10
#  - btrfs raid.
#  - LVM
#  - dmcrypt
#  - dmraid

DISK1=sdb1
DISK2=sdc1
DISK3=sdd1
DISK4=
TARGET=/mnt/test

#############################################################################################
TAINT=$(cat /proc/sys/kernel/tainted)

check_tainted()
{
    if [ "$(cat /proc/sys/kernel/tainted)" != $TAINT ]; then
      echo ERROR: Taint flag changed $(cat /proc/sys/kernel/tainted)
      exit
    fi  
}

#############################################################################################
# setup/teardown helper routines.

# Clear the first part of the disks to make mdadm not complain on subsequent creations.
clearsuper()
{
  dd if=/dev/zero of=/dev/$DISK1 bs=1M count=10 2> /dev/null &
  if [ "$DISK2" != "" ]; then
    dd if=/dev/zero of=/dev/$DISK2 bs=1M count=10 2> /dev/null &
  fi
  if [ "$DISK3" != "" ]; then
    dd if=/dev/zero of=/dev/$DISK3 bs=1M count=10 2> /dev/null &
  fi
  if [ "$DISK4" != "" ]; then
    dd if=/dev/zero of=/dev/$DISK4 bs=1M count=10 2> /dev/null &
  fi
  wait
  echo Cleared partition header.
}

stopraid()
{
  mdadm --manage --stop /dev/md/md0
  echo stopped md0
}

#############################################################################################
# RAID 0 creation helpers

raid0_2()
{
  echo "Testing RAID0 (2 disks)"
  clearsuper

  mdadm --create -f --run md0 --level 0 --raid-devices 2 --rounding 64 /dev/$DISK1 /dev/$DISK2
  echo created RAID0
}

raid0_3()
{
  echo "Testing RAID0 (3 disks)"
  clearsuper

  mdadm --create -f --run md0 --level 0 --raid-devices 3 --rounding 64 /dev/$DISK1 /dev/$DISK2 /dev/$DISK3
  echo created RAID0
}

raid0_4()
{
  echo "Testing RAID0 (4 disks)"
  clearsuper

  mdadm --create -f --run md0 --level 0 --raid-devices 4 --rounding 64 /dev/$DISK1 /dev/$DISK2 /dev/$DISK3 /dev/$DISK4
  echo created RAID0
}

#############################################################################################
# RAID 1 creation helpers

raid1_2()
{
  echo "Testing RAID1 (2 disks)"
  clearsuper

  mdadm --create -f --run md0 --level 1 --raid-devices 2 /dev/$DISK1 /dev/$DISK2
  echo created RAID1
}

raid1_3()
{
  echo "Testing RAID1 (3 disks)"
  clearsuper

  mdadm --create -f --run md0 --level 1 --raid-devices 3 /dev/$DISK1 /dev/$DISK2 /dev/$DISK3
  echo created RAID1
}

raid1_4()
{
  echo "Testing RAID1 (4 disks)"
  clearsuper

  mdadm --create -f --run md0 --level 1 --raid-devices 3 /dev/$DISK1 /dev/$DISK2 /dev/$DISK3 /dev/$DISK4
  echo created RAID1
}

#############################################################################################
# RAID 5 creation helpers

raid5_3()
{
  echo "Testing RAID5 (3 disks)"
  clearsuper

  mdadm --create -f --run md0 --level 5 --raid-devices 3 /dev/$DISK1 /dev/$DISK2 /dev/$DISK3
  echo created RAID5
}

raid5_3_missing()
{
  echo "Testing RAID5 (3 disks + 1 missing)"
  clearsuper

  mdadm --create -f --run md0 --level 5 --raid-devices 4 /dev/$DISK1 /dev/$DISK2 /dev/$DISK3 missing
  echo created RAID5
}

raid5_4()
{
  echo "Testing RAID5 (4 disks)"
  clearsuper

  mdadm --create -f --run md0 --level 5 --raid-devices 4 /dev/$DISK1 /dev/$DISK2 /dev/$DISK3 /dev/$DISK4
  echo created RAID5
}

#############################################################################################
# Instantiate a storage type

# 1 disk tests

setup_1disk()
{
	case "$1" in
	1)	mkfs.btrfs -f /dev/$DISK1
		;;
	2)	mkfs.ext4 -F -q /dev/$DISK1
		;;
	3)	mkfs.ext4 -F -q -b 1024 /dev/$DISK1
		;;
	4)	mkfs.xfs -f -q /dev/$DISK1
		;;
	esac
	mount /dev/$DISK1 $TARGET
}

NUM_1DISK_TYPES=4

teardown_1disk()
{
	umount $TARGET
}

# 2 disk tests

setup_2disks()
{
	case "$1" in
	1)	raid0_2
		mkfs.btrfs -f /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	2)	raid0_2
		mkfs.ext4 -F -q /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	3)	raid0_2
		mkfs.ext4 -F -q -b 1024 /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	4)	raid0_2
		mkfs.xfs -f -q /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	5)	raid1_2
		mkfs.btrfs -f /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	6)	raid1_2
		mkfs.ext4 -F -q /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	7)	raid1_2
		mkfs.ext4 -F -q -b 1024 /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	8)	raid1_2
		mkfs.xfs -f -q /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	esac
}

NUM_2DISK_TYPES=8

teardown_2disks()
{
	case "$1" in
	*)	umount $TARGET
		stopraid
		;;
	esac
}

#############################################################################################
# 3 disk tests

setup_3disks()
{
	case "$1" in
	1)	raid0_3
		mkfs.btrfs -f /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	2)	raid0_3
		mkfs.ext4 -F -q /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	3)	raid0_3
		mkfs.ext4 -F -q -b 1024 /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	4)	raid0_3
		mkfs.xfs -f -q /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	5)	raid1_3
		mkfs.btrfs -f /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	6)	raid1_3
		mkfs.ext4 -F -q /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	7)	raid1_3
		mkfs.ext4 -F -q -b 1024 /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	8)	raid1_3
		mkfs.xfs -f -q /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	9)	raid5_3
		mkfs.btrfs -f /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	10)	raid5_3
		mkfs.ext4 -F -q /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	11)	raid5_3
		mkfs.ext4 -F -q -b 1024 /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	12)	raid5_3
		mkfs.xfs -f -q /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	13)	raid5_3_missing
		mkfs.btrfs -f /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	14)	raid5_3_missing
		mkfs.ext4 -F -q /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	15)	raid5_3_missing
		mkfs.ext4 -F -q -b 1024 /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	16)	raid5_3_missing
		mkfs.xfs -f -q /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;

	esac
}
NUM_3DISK_TYPES=16

teardown_3disks()
{
	case "$1" in
	*)	umount $TARGET
		stopraid
		;;
	esac
}

#############################################################################################
# 4 disk tests

setup_4disks()
{
	case "$1" in
	1)	raid0_4
		mkfs.btrfs -f /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	2)	raid0_4
		mkfs.ext4 -F -q /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	3)	raid0_4
		mkfs.ext4 -F -q -b 1024 /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	4)	raid0_4
		mkfs.xfs -f -q /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	5)	raid1_4
		mkfs.btrfs -f /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	6)	raid1_4
		mkfs.ext4 -F -q /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	7)	raid1_4
		mkfs.ext4 -F -q -b 1024 /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	8)	raid1_4
		mkfs.xfs -f -q /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	9)	raid5_4
		mkfs.btrfs -f /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	10)	raid5_4
		mkfs.ext4 -F -q /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	11)	raid5_4
		mkfs.ext4 -F -q -b 1024 /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	12)	raid5_4
		mkfs.xfs -f -q /dev/md/md0
		mount /dev/md/md0 $TARGET
		;;
	esac
}
NUM_4DISK_TYPES=12

teardown_4disks()
{
	case "$1" in
	*)	umount $TARGET
		stopraid
		;;
	esac
}


#############################################################################################
# Call the various fs stress programs.
do_tests()
{
  pushd $TARGET >/dev/null

  /usr/local/bin/fsx -N 10000 -S0 foo
  /usr/local/bin/fsstress -d . -n 10000 -p 8 -r

  check_tainted
  popd >/dev/null
}

#############################################################################################
# main()

# 1 disk tests
for test in $(seq 1 $NUM_1DISK_TYPES)
do
  echo "doing 1 disk test "$test"/"$NUM_1DISK_TYPES
  setup_1disk $test
  do_tests
  teardown_1disk $test
  echo
done

# 2 disk tests
if [ "$DISK2" != "" ]; then
  for test in $(seq 1 $NUM_2DISK_TYPES)
  do
    echo "doing 2 disk test "$test"/"$NUM_2DISK_TYPES
    setup_2disks $test
    do_tests
    teardown_2disks $test
    echo
  done
fi

# 3 disk tests
if [ "$DISK3" != "" ]; then
  for test in $(seq 1 $NUM_3DISK_TYPES)
  do
    echo "doing 3 disk test "$test"/"$NUM_3DISK_TYPES
    setup_3disks $test
    do_tests
    teardown_3disks $test
    echo
  done
fi

# 4 disk tests
if [ "$DISK4" != "" ]; then
  for test in $(seq 1 $NUM_4DISK_TYPES)
  do
    echo "doing 4 disk test "$test"/"$NUM_4DISK_TYPES
    setup_4disks $test
    do_tests
    teardown_4disks $test
    echo
  done
fi

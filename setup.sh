#!/bin/sh
#
# Storage/fs tests.
#
# TODO: btrfs raid.

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
# do the actual tests. This gets run in the target dir.

do_tests()
{
    /usr/local/bin/fsx -N 1000 -S0 foo
}

#############################################################################################
fs_loop()
{
  for FS in xfs btrfs ext4 ext4-1k
  do
    case "$FS" in
    btrfs)
	mkfs.btrfs -f /dev/md/md0
        ;;
    ext4)
	mkfs.ext4 -F -q /dev/md/md0
	;;
    ext4-1k)
	mkfs.ext4 -F -q -b 1024 /dev/md/md0
	;;
    xfs)
	mkfs.xfs -f -q /dev/md/md0
	;;
    esac

    echo Created $FS

    mount /dev/md/md0 $TARGET
    pushd $TARGET
    do_tests
    check_tainted
    popd > /dev/null
    umount $TARGET
  done
}

#############################################################################################
# setup/teardown routines.

# Clear the first part of the disks to make mdadm not complain on subsequent creations.
clearsuper()
{
  dd if=/dev/zero of=/dev/$DISK1 bs=1M count=10 2> /dev/null &
  dd if=/dev/zero of=/dev/$DISK2 bs=1M count=10 2> /dev/null &
  dd if=/dev/zero of=/dev/$DISK3 bs=1M count=10 2> /dev/null &
  wait
  echo Cleared partition header.
}

stopraid()
{
  mdadm --manage --stop /dev/md/md0
  echo stopped md0
  echo
}

#############################################################################################
# RAID 0 tests

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
# RAID 1 tests

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
# RAID 5 tests

raid5_3()
{
  echo "Testing RAID5 (3 disks)"
  clearsuper

  mdadm --create -f --run md0 --level 1 --raid-devices 3 /dev/$DISK1 /dev/$DISK2 /dev/$DISK3
  echo created RAID5
}

raid5_4()
{
  echo "Testing RAID5 (4 disks)"
  clearsuper

  mdadm --create -f --run md0 --level 1 --raid-devices 4 /dev/$DISK1 /dev/$DISK2 /dev/$DISK3 /dev/$DISK4
  echo created RAID5
}

#############################################################################################
# main()

# 2 disk tests
for setup in raid0_2 raid1_2
do
  $setup
  fs_loop
  stopraid
done

# 3 disk tests
if [ "$DISK3" != "" ]; then
  echo "Testing three disk configurations."
  for setup in raid0_3 raid1_3 raid5_3
  do
    $setup
    fs_loop
    stopraid
  done
fi

# 4 disk tests
if [ "$DISK4" != "" ]; then
  echo "Testing four disk configurations."
  for setup in raid0_4 raid1_4 raid5_4
  do
    $setup
    fs_loop
    stopraid
  done
fi


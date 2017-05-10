#!/bin/bash

#-------------------------------------------------------------------------------------------

function initvm {

echo "unbind AMD Radeon HD 7750 GPU from radeon kernel module"
echo -n '0000:01:00.0' >/dev/null /sys/bus/pci/drivers/radeon/unbind
#echo '0000:01:00.0' >/dev/null | tee /sys/bus/pci/devices/0000:01:00.0/driver/unbind

echo "bind AMD Radeon HD 7750 GPU to vfio-pci kernel module"
echo -n '0000:01:00.1' >dev/null /sys/bus/pci/drivers/vfio-pci/bind

echo "unbind AMD Radeon HD 7750 HDMI Audio device from snd_hda_intel kernel module" 
echo -n '0000:01:00.1' >/dev/null /sys/bus/pci/drivers/snd_hda_intel/unbind
#echo '0000:01:00.1' >/dev/null | tee /sys/bus/pci/devices/0000:01:00.1/driver/unbind

echo "bind AMD Radeon HD 7750 HDMI Audio device to vfio-pci kernel module" 
echo -n '0000:01:00.1' >/dev/null /sys/bus/pci/drivers/vfio-pci/bind 

echo "load kernel modules:"

echo " vfio"
modprobe vfio
echo " vfio-pci"
modprobe vfio-pci
echo " vfio-net"
modprobe virtio-net
echo " virtio-pci"
modprobe virtio-pci
echo " virtio-blk"
modprobe virtio-blk
echo " virtio-balloon"
modprobe virtio-balloon
echo " virtio-ring"
modprobe virtio-ring
echo " virtio"
modprobe virtio
echo " kvm-amd"
modprobe kvm-amd

echo "give AMD Radeon HD 7750 GPU new vfio-pci id"
echo 1002 683f >/dev/null /sys/bus/pci/drivers/vfio-pci/new_id

echo "give AMD Radeon HD 7750 HDMI Audio device new vfio-pci id"
echo 1002 aab0 >/dev/null /sys/bus/pci/drivers/vfio-pci/new_id

echo "set host audio driver to use for guest"

#export QEMU_AUDIO_DRV=pa
#export QEMU_PA_SAMPLES=1024
export QEMU_AUDIO_DRV=alsa
export QEMU_PA_SAMPLES=128
export QEMU_ALSA_ADC_BUFFER_SIZE=1024 QEMU_ALSA_ADC_PERIOD_SIZE=256
export QEMU_ALSA_DAC_BUFFER_SIZE=1024 QEMU_ALSA_DAC_PERIOD_SIZE=256
export QEMU_AUDIO_DAC_FIXED_SETTINGS=1
export QEMU_AUDIO_DAC_FIXED_FREQ=44100 QEMU_AUDIO_DAC_FIXED_FMT=S16 QEMU_AUDIO_ADC_FIXED_FREQ=44100 QEMU_AUDIO_ADC_FIXED_FMT=S16
export QEMU_AUDIO_DAC_TRY_POLL=1 QEMU_AUDIO_ADC_TRY_POLL=1
export QEMU_AUDIO_TIMER_PERIOD=50


}

#-------------------------------------------------------------------------------------------

function timestart {

DATESTART=$(date +%s)

}

#-------------------------------------------------------------------------------------------

function timenow {

TIMENOW=$(echo "$(date +%s) - 60" | bc)

}

#-------------------------------------------------------------------------------------------

function runvm {

echo "virtual machine started"

qemu-system-x86_64 \
    -realtime mlock=on \
    -enable-kvm \
    -cpu host,hv_time,hv_relaxed,hv_vapic,hv_spinlocks=0x1fff \
    -smp sockets=1,cores=8,threads=1 \
    -m 16G \
    -rtc base=localtime,clock=host \
    -drive format=raw,file=/home/yuki/Virtual\ Disk\ Images/win10.img \
    -device vfio-pci,host=01:00.0,multifunction=on,x-vga=on \
    -device vfio-pci,host=01:00.1 \
    -net nic,model=virtio \
    -net tap,ifname=tap0,script=no,downscript=no \
    -display none \
    -vga none #2>/dev/null


#   -soundhw hda \
#   -drive file=/dev/sdd,media=disk,aio=threads,format=raw \
#   -drive file=/dev/sde,media=disk,aio=threads,format=raw \
#   -usb -usbdevice host:04d9:2011 \
#   -usb -usbdevice host:1532:0034 \
#   -net nic,model=virtio -net user,smb=/media/yuki/Data\ 1 \
#   -net nic,model=rtl8139 -net tap,ifname=tap0,script=no,downscript=no \
#   -usbdevice tablet \
#   -boot d -cdrom /media/yuki/Data\ 2/Operating\ Systems/Windows/Win10/Windows\ 10\ Pro\ x64.iso \

echo "virtual machine stopped" 

}

#-------------------------------------------------------------------------------------------

while true; do
    initvm
    timestart
    runvm
    timenow
    if [ "$DATESTART" -le "$TIMENOW" ]
    then
        echo "done"
        break
    else
        echo "VM only ran for 60 seconds or less, restarting..."
	continue
    fi
done

exit 

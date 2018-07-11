#Kernel Filename

#JUST make sure it is 8.3 format compliant
Name="WaVeOs" # <-- has to be less than 9 characters
extention="elf" #<-- has to be less than 4 characters



name83=$Name
while (( "${#name83}" < "8" )) ; do
	name83="$name83 "
done
name83="$name83""$extention"
while (( "${#name83}" < "11" )) ; do
	name83="$name83 "
done
name83=$(echo "$name83" | awk '{print toupper($0)}')





#Boot device

#Label of FAT32 partition on my pendrive
PartLabel="WAVEOS"
MountPath="$PWD/mnt"
PartPath="/dev/disk/by-label/$PartLabel"

#Source files' directories
Kernel="$PWD/Kernel"
Assembly="$PWD/Assembly"
Include="$PWD/Kernel/include"
Linker="$PWD/linker.ld"
#compiled/linked files' directories
Obj="$PWD/obj"
Binary="$PWD/bin"

#Path to CROSS COMPILER
Compiler="$PWD/../../cross/bin"



#Installing programs needed for compilation
clear
echo "Obtaining necessary software...";
sudo apt install inotify-tools;
sudo apt install nasm;

clear

#Detecting if device is online and ready

echo "Searching for debug device..."

if [ -e $PartPath ] ; then
	echo "Found debug device: $PartLabel";
	echo "Press any key to continue";
  read -n1 -r
else
	echo 'ERROR! Boot Partition not found!';
	exit;
fi

clear
echo "Ready!"

#Main loop

#If any of source files were modified - recompile and copy

while sudo inotifywait -r -e  close_write $Kernel $Include $Assembly -q; do
clear

#Check if device is ready - everytime
echo "Searching for debug device..."
if [ ! -e $PartPath ] ; then
	echo 'ERROR! Boot Partition not found!';
	exit;
fi

#Delete old binaries
rm -rf $Binary/*;
rm -rf $Obj/*;
rm -rf $MountPath/*

#Assemble pure binary files
echo
echo "Assembling pure binary files:"

error="0";
for f in $Assembly/*.asm
do
	OutFile=${f##*/}
  echo $OutFile
  OutFile=${OutFile%\.*}
 if [[ -n $(nasm -s -d kernFilename=\'"$name83"\' -f bin -o "$Binary/$OutFile.bin" $f) ]]; then
	echo $(nasm -s -d kernFilename=\'"$name83"\' -f bin -o "$Binary/$OutFile.bin" $f)
	error="1";
 fi

done
if [[ "$error" -eq "1" ]]; then
	error="0";
	continue;
fi

#Assemble .asm files integrated into kernel
echo
echo "Assembling kernel parts:"

for f in $Kernel/*.asm
do
	OutFile=${f##*/}
  echo $OutFile
  OutFile=${OutFile%\.*}
 if [[ -n $(nasm -s -f elf -o "$Obj/$OutFile.o" $f) ]]; then
	echo $(nasm -s -f elf -o "$Obj/$OutFile.o" $f)
	error="1";
 fi

done
if [[ "$error" -eq "1" ]]; then
	error="0";
	continue;
fi


#Compile .cpp files integrated into kernel
echo
echo "Compiling kernel parts:"

for f in $Kernel/*.cpp
do
 OutFile=${f##*/}
 echo $OutFile
 OutFile=${OutFile%\.*}
 if ! $Compiler/i386-elf-g++ -ffreestanding -O2 -Wall -Wextra -fno-exceptions -fno-rtti -c $f -o $Obj/$OutFile.o ; then
	error="1";
 fi
done
if [[ "$error" -eq "1" ]]; then
	error="0";
	continue;
fi
#Link kernel - assembled and compiled parts
echo
echo "Linking Kernel from obj files... "
if ! $Compiler/i386-elf-g++ -T $Linker -o $Binary/$Name.$extention -ffreestanding -O2 -nostdlib $Obj/*.o -lgcc ; then
 continue;
fi
#mount boot device/partition
echo
echo "Mounting Device at $PartPath..."
sudo mount $PartPath $MountPath

#copy executable files
echo
echo "Copying binaries..."
sudo cp $Binary/* $MountPath/
#unmount boot device/partition
echo
echo "Unmounting Device..."
sudo sync
sudo umount $PartPath
sudo sync
#write some informations
echo
echo "Should be done!"
echo
date +%D;
date +%T;
echo
for f in $Binary/*
do
 OutFile=${f##*/}
 echo "$OutFile size: $(wc -c $f | awk '{print $1}') bytes"
done
done

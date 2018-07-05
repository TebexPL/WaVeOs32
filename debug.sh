#Boot device ID
DeviceID="usb-Sony_Storage_Media_5C070B6A80332B2F06-0:0"
DevicePath="/dev/disk/by-id/$DeviceID"
#Checking for necessary software
clear
echo "Obtaining necessary software"
sudo apt install bochs
sudo apt install bochs-sdl
clear
#checking if Boot device is avaliable
	echo "Searching for debug device..."
if [ -e $DevicePath ] ; then

	echo "Boot device found: $DeviceID";
	read -s -n1  key
else
	echo 'ERROR! Boot device not found!';
	exit;
fi


#main Loop - chceck if user pressed a key - if yes- run bochs simulation
while true; do
clear
echo "Press any key to debug...";
read -s -n1  key
clear
	echo "Searching for debug device..."
if [ ! -e $DevicePath ] ; then
	clear
	echo 'ERROR! Boot device not found!';
	exit;
fi
sudo bochs -q -f bochs.conf;
done

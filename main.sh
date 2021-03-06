echo "hello world"

# Utils
__contains () {
    echo "$1" | tr ' ' '\n' | grep -F -x -q "$2"
}

# Main information

hostname=""
username=""
userpassword=""
userpassword1=""
rootpassword=""
timezone=""
locale=""

freedisk="$(df /dev/sda --out=avail -k -m | tail -1)"

homespace="$(( $freedisk / 1000 - 26))"

# Disk space check
if [ $freedisk -le "5000" ]
  then
    echo "Your disk space is less than 50GB, you require minimum of 50GB for this installation!"
    exit
fi

echo "Welcome to simple clean Arch linux installation!"

# Main information

__start() {

    #call host function
    __hostname
    clear

    #call username function
    __username
    clear

    #call password function
    __password
    clear

    #call rootpassword function
    __rootpassword
    clear

    #call locale function
    __locale
    clear

    #call time zone function
    __timezone
    clear

    #review changes and ask if need to retype all changes
    echo "Information Summary: 
    \n Hostname: ${hostname}
    \n Username: ${username}
    \n Password: ${userpassword}
    \n Root: ${rootpassword}
    \n Timezone: ${timezone}
    \n Locale: ${locale}"

    echo "Do you want to change this data? [y/n]"
    read question1

    if [ "$question1" = "y" ]; then 
        __start
    fi

    loadkeys es
    timedatectl set-ntp true

    __disk
    __mount
    __install
    __configureTime
    __configureUsers
    __extra

    clear

    exit
    umount -R /mnt

    clear

    echo "Installation successfully!, you can now reboot it"

}

# Install extra packages
__extra() {

    arch-chroot /mnt
    
    pacman -S sudo

    echo "%wheel ALL=(ALL) ALL" > /etc/sudoers
    
    exit

}

# Configure users
__configureUsers() {

    arch-chroot /mnt

    passwd
    ${rootpassword}
    
    useradd -m ${username}
    passwd ${username}
    ${userpassword}
    usermod -aG wheel,video,audio,storage ${username}

    exit

}

# Configure Local Time and Timezone
__configureTime() {

    arch-chroot /mnt

    ln -sf /usr/share/zoneinfo/${timezone} /etc/localtime

    hwclock --systohc

    echo "${locale}.UTF-8 UTF-8" > /etc/locale.gen

    locale-gen

    echo "LANG=${locale}.UTF-8" > /etc/locale.conf

    splitLocale=(${IN//_/ })

    echo "KEYMAP=${splitLocale[0]}" > /etc/locale.conf

    echo "${hostname}" > /etc/hostname

    echo "127.0.0.1 localhost" > /etc/hosts
    echo "::1 localhost" > /etc/hosts
    echo "127.0.1.1 ${hostname}.localdomain ${username}" > /etc/hosts

    exit

}

# Install linux and other packages
__install() {
    pacstrap /mnt base base-devel linux linux-firmware efibootmgr networkmanager grub

    genfstab -U /mnt >> /mnt/etc/fstab

}

# Mount disks and set file format type
__mount() {
    mkfs.vfat -F32 /dev/sda1

    mkswap /dev/sda2
    swapon /dev/sda2

    mkfs.ext4 /dev/sda3
    mkfs.ext4 /dev/sda4

    mount /dev/sda3 /mnt

    mkdir /mnt/home
    mount /dev/sda4 /mnt/home

    mkdir -p /mnt/boot/efi
    mount /dev/sda1 /mnt/boot/efi

}

# Partition disk
__disk() {

    fdisk /dev/sda

    #create EFI table
    g

    #create EFI partition
    n
    p
    1
    1G
    t
    1
    1

    #create SWAP partition
    n
    p
    2
    5G
    t
    2
    t
    82

    #create ROOT partition
    n
    p
    3
    20G

    #create HOME partition
    n
    p
    4
    28
    ${homespace}G

    w
}

__hostname() {
    echo "Type the hostname for your pc"
    read hostname
}

__username() {
    
    invalidnames="root admin user sudo cd debian linux cache users ds ls disk username"

    echo "type the username for log in"
    read username

    if __contains "$invalidnames" "${username}" ; then
        echo "Invalid username, re type new username"
        __username
    fi

}


__password() {
    
    userpassword1=""
    userpassword=""

    echo "Type the password for log in "
    read userpassword1

    echo "Re-type the password for log in "
    read userpassword

    if [ "$userpassword1" = "$userpassword" ]; then
        echo "Passwords match!."
    else
        echo "Passwords are not equal."
        __password
    fi

}

__rootpassword() {
    echo "Type root password for superadmin access"
    read rootpassword
}

__timezone() {
    echo "Type your timezone"
    read timezone
}

__locale() {
    echo "Type your location"
    read locale
}

__start

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

freedisk=$(fdisk -l | awk '{print $3}' | grep -v "[A-Za-z.]" | paste -s)

homespace="$(( $freedisk - 26))"

echo ${freedisk}gb

# Disk space check
if [ $freedisk -le "50" ]
  then
    echo "Your disk space is less than 50GB, you require minimum of 50GB for this installation!"
    exit
fi

echo "Welcome to simple clean Arch linux installation!"

# Main information

__start() {

    #call host function
    clear
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
    Hostname: ${hostname}
    Username: ${username}
    Password: ${userpassword}
    Root: ${rootpassword}
    Timezone: ${timezone}
    Locale: ${locale}"

    echo "Do you want to change this data? [y/n]"
    read question1

    if [ "$question1" = "y" ]; then 
        __start
    fi

    loadkeys es
    timedatectl set-ntp true

    __disk
    __mount
    arch-chroot /mnt /bin/bash ls
    __install
    __configureTime
    __configureUsers
    __extra

    clear

    umount -R /mnt

    clear

    echo "Installation successfully!, you can now reboot it"

}

# Install extra packages
__extra() {
    
    pacman -S sudo

    echo "%wheel ALL=(ALL) ALL" > /mnt/etc/sudoers

}

# Configure users
__configureUsers() {

    arch-chroot /mnt /bin/bash 'grub-install --efi-directory="/boot/efi" --target=x86_64-efi'
    arch-chroot /mnt /bin/bash 'grub-mkconfig -o boot/grub/grub.cfg'

    arch-chroot /mnt /bin/bash passwd
    arch-chroot /mnt /bin/bash ${rootpassword}
    
    arch-chroot /mnt /bin/bash 'useradd -m ${username}'
    arch-chroot /mnt /bin/bash 'passwd ${username}'
    arch-chroot /mnt /bin/bash ${userpassword}
    arch-chroot /mnt /bin/bash 'usermod -aG wheel,video,audio,storage ${username}'
}

# Configure Local Time and Timezone
__configureTime() {

    arch-chroot /mnt /bin/bash 'ln -sf /usr/share/zoneinfo/${timezone} /etc/localtime'

    arch-chroot /mnt /bin/bash 'hwclock --systohc'

    arch-chroot /mnt /bin/bash 'echo "${locale}.UTF-8 UTF-8" > /etc/locale.gen'

    arch-chroot /mnt /bin/bash 'locale-gen'

    arch-chroot /mnt /bin/bash 'echo "LANG=${locale}.UTF-8" > /etc/locale.conf'

    splitLocale=(${locale//_/ })

    arch-chroot /mnt /bin/bash 'echo "KEYMAP=${splitLocale[0]}" > /etc/locale.conf'

    arch-chroot /mnt /bin/bash 'echo "${hostname}" > /etc/hostname'

    arch-chroot /mnt /bin/bash 'echo "127.0.0.1 localhost" > /etc/hosts'
    arch-chroot /mnt /bin/bash 'echo "::1 localhost" > /etc/hosts'
    arch-chroot /mnt /bin/bash 'echo "127.0.1.1 ${hostname}.localdomain ${username}" > /etc/hosts'

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

    clear
    
    echo "Do you want to do partitions manual? [y/n]"
    echo "WARNING: you need your partition table format like this:"

    echo "dev/sda1 = EFI System or BIOS"
    echo "dev/sda2 = Linux Swap"
    echo "dev/sda3 = Root (Linux filesystem)"
    echo "dev/sda4 = Home (linux home)"

    read question2

    if [ "$question2" = "y" ]; then 
        cfdisk
    else
        __auto
    fi

}

__auto () {

    #create GPT table
    parted /dev/sda mklabel gpt

    #create EFI partition
    parted /dev/sda mkpart P1 ext4 1MiB 1GiB
    parted /dev/sda set 1 esp on

    #create SWAP partition
    parted /dev/sda mkpart P2 linux-swap 1GiB 5GiB

    #create ROOT partition
    parted /dev/sda mkpart P3 ext4 5GiB 25GiB

    #create HOME partition
    parted /dev/sda mkpart P4 ext4 25GiB 100%

    fdisk -l

    echo "You like to change this partitions? [y/n]"
    read question3

    if [ "$question3" = "y" ]; then 
        cfdisk
    fi

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

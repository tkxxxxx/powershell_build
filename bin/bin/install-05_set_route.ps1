# ���������� ===================================================================
# ���W���[���̓ǂݍ���
foreach ($func in (get-childitem (join-path $myinvocation.mycommand.path "..\func_*"))) {
	import-module $func
}

# �^�C�g����\��
show-title "�ÓI���[�g�̐ݒ�"

# ���C������ ===================================================================
# �f�t�H���g�Q�[�g�E�F�C�����Ȃ��C���^�t�F�C�X���m�F
$defroute = get-netroute -destinationprefix "0.0.0.0/0"
$ifi = $defroute.ifindex
if ($ifi -eq (get-netadapter -name "Front*").ifindex) {
    $routeif = (get-netadapter -name "Back*").ifindex
} else {
    $routeif = (get-netadapter -name "Front*").ifindex
}

$destnw = ""
while (-not ($destnw -match "^[Qq]$")) {
    message-step "���݂̃��[�e�B���O�e�[�u����\�����܂��B"
    get-netroute -addressfamily ipv4 | where {$_.nexthop -ne "0.0.0.0"} | select destinationprefix, nexthop | format-table

    message-step "���[�g��ǉ�����ꍇ�̓��[�g���A�I������ꍇ�� q ����͂��܂��B"
    write-host "> " -nonewline -foregroundcolor green
    write-host "�l�b�g���[�N�A�h���X (x.x.x.x/x, q) > " -nonewline -foregroundcolor yellow
    $destnw = read-host

    if ($destnw -match "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$") {
        
        $destgw = ""
        while (-not ($destgw -match "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$")) {
            write-host "> " -nonewline -foregroundcolor green
            write-host "�Q�[�g�E�F�C (x.x.x.x)�@�@�@�@�@�@�@> " -nonewline -foregroundcolor yellow
            $destgw = read-host
        }

        message-step "�ȉ��̐ÓI���[�g��ǉ����܂��B"
        write-host "> " -nonewline -foregroundcolor green
        write-host "���[�g > " -nonewline -foregroundcolor yellow
        write-host "$destnw via $destgw"
        write-host ""
        wait-yninput

        message-stepstart "�ÓI���[�g��ǉ����܂�"
        new-netroute -destinationprefix $destnw -interfaceindex $routeif -nexthop $destgw -confirm:$false | out-null
        message-stepresult $?

    }
}


while (-not ($ping -match "^[Qq]$")) {
    $ping = ""
    message-step "ping ���m�F����ꍇ�� IP �A�h���X�A�I������ꍇ�� q ����͂��܂��B"
    write-host "> " -nonewline -foregroundcolor green
    write-host "���� IP �A�h���X (x.x.x.x, q) > " -nonewline -foregroundcolor yellow
    $ping = read-host

    if ($ping -match "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$") {
        
        $cmd = "ping $ping"
        invoke-expression $cmd
    }
}

write-host ""
# �㑱�X�N���v�g�̌Ăяo��
invoke-nextscript -script (join-path $myinvocation.mycommand.path "..\..\install-06_reboot.bat")
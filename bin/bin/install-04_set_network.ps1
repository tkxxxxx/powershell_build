# ���������� ===================================================================
# ���W���[���̓ǂݍ���
foreach ($func in (get-childitem (join-path $myinvocation.mycommand.path "..\func_*"))) {
	import-module $func
}

# �^�C�g����\��
show-title "�l�b�g���[�N�̐ݒ�"

# ���C������ ===================================================================
# �m�F���b�Z�[�W�̕\��
message-step "���ݐڑ�����Ă��� NIC �̖��O���ȉ��̒ʂ�ύX���܂��B"
$i = 1
$newnics = get-netadapter | sort name | %{
    $nic = "" | select OldName, MacAddress, LinkSpeed, NewName
    $nic.oldname = $_.name
    $nic.macaddress = $_.macaddress
    $nic.linkspeed = $_.linkspeed
    $nic.newname = "LAN $i"
    $i += 1
    $nic
}
$newnics | format-table
wait-yninput

message-stepstart "NIC �̖��O��ύX���܂�"
$res = $true

foreach ($nic in $newnics) {
    rename-netadapter -name $nic.oldname -newname $nic.newname
    if (-not $?) {
        $res = $false
    }
}
message-stepresult $res

message-step "�ݒ肷��n�[�g�r�[�g�l�b�g���[�N�̐�����͂��Ă��������B"
$hbnum = ""
while (-not ($hbnum -match "^[0-2]$")) {
    write-host "> " -nonewline -foregroundcolor green
    write-host "�n�[�g�r�[�g�� (0-2) > " -nonewline -foregroundcolor yellow
    $hbnum = read-host
}

message-step "�ȉ��̃����o�Ń`�[�~���O�f�o�C�X���쐬���܂�"
$teaminfo = (
    @{
        "LAN 1" = "Front";
        "LAN 2" = "Front";
        "LAN 3" = "Back";
        "LAN 4" = "Back";
        "LAN 5" = "-";
        "LAN 6" = "-";
    }, @{
        "LAN 1" = "Front";
        "LAN 2" = "Front";
        "LAN 3" = "Back";
        "LAN 4" = "Back";
        "LAN 5" = "HB1";
        "LAN 6" = "HB1";
    }, @{
        "LAN 1" = "Front";
        "LAN 2" = "Front";
        "LAN 3" = "Back";
        "LAN 4" = "Back";
        "LAN 5" = "HB1";
        "LAN 6" = "HB2";
    }
)

$newteams = get-netadapter | sort name | %{
    $nic = "" | select Name, MacAddress, LinkSpeed, Team
    $nic.name = $_.name
    $nic.macaddress = $_.macaddress
    $nic.linkspeed = $_.linkspeed
    $nic.team = $teaminfo[$hbnum][$nic.name]
    $nic
}
$newteams | format-table
wait-yninput

message-stepstart "�`�[�~���O�f�o�C�X Front ���쐬���܂�"
new-netlbfoteam -name "Front" -teammembers ("LAN 1", "LAN 2") -teamingmode switchindependent -loadbalancingalgorithm dynamic -confirm:$false | out-null
message-stepresult $?

message-stepstart "�`�[�~���O�f�o�C�X Front �� LAN 2 ���X�^���o�C�A�_�v�^�Ɏw�肵�܂�"
set-netlbfoteammember -name "LAN 2" -administrativemode standby -confirm:$false | out-null
message-stepresult $?

message-stepstart "�`�[�~���O�f�o�C�X Back ���쐬���܂�"
new-netlbfoteam -name "Back" -teammembers ("LAN 3", "LAN 4") -teamingmode switchindependent -loadbalancingalgorithm dynamic -confirm:$false | out-null
message-stepresult $?

message-stepstart "�`�[�~���O�f�o�C�X Back �� LAN 4 ���X�^���o�C�A�_�v�^�Ɏw�肵�܂�"
set-netlbfoteammember -name "LAN 4" -administrativemode standby -confirm:$false | out-null
message-stepresult $?

if ($hbnum -eq 1) {
    message-stepstart "�`�[�~���O�f�o�C�X HB1 ���쐬���܂�"
    new-netlbfoteam -name "HB1" -teammembers ("LAN 5", "LAN 6") -teamingmode switchindependent -loadbalancingalgorithm dynamic -confirm:$false | out-null
    message-stepresult $?

    message-stepstart "�`�[�~���O�f�o�C�X HB1 �� LAN 6 ���X�^���o�C�A�_�v�^�Ɏw�肵�܂�"
    set-netlbfoteammember -name "LAN 6" -administrativemode standby -confirm:$false | out-null
    message-stepresult $?
} 

if ($hbnum -eq 2) {
    message-stepstart "�`�[�~���O�f�o�C�X HB1 ���쐬���܂�"
    new-netlbfoteam -name "HB1" -teammembers "LAN 5" -teamingmode switchindependent -loadbalancingalgorithm dynamic -confirm:$false | out-null
    message-stepresult $?

    message-stepstart "�`�[�~���O�f�o�C�X HB2 ���쐬���܂�"
    new-netlbfoteam -name "HB2" -teammembers "LAN 6" -teamingmode switchindependent -loadbalancingalgorithm dynamic -confirm:$false | out-null
    message-stepresult $?
} 

message-step "�쐬���ꂽ�`�[�~���O�f�o�C�X���m�F���Ă��������B"
get-netlbfoteam | select name, members, teamingmode, loadbalancingalgorithm | sort name | format-table
wait-yninput

message-step "�쐬���ꂽ�`�[�~���O�f�o�C�X�̃����o���m�F���Ă��������B"
get-netlbfoteammember | select team, name, administrativemode | sort name | format-table
wait-yninput


message-step "�t�����g���l�b�g���[�N�̍\��������͂��Ă�������"
$fipandsubnet = ""
$fvlan = ""
while (-not ($fipandsubnet -match "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$")) {
    write-host "> " -nonewline -foregroundcolor green
    write-host "�t�����g�� IP �A�h���X (x.x.x.x/x) > " -nonewline -foregroundcolor yellow
    $fipandsubnet = read-host
}
while (-not ($fvlan -match "^[0-9]{1,4}")) {
    write-host "> " -nonewline -foregroundcolor green
    write-host "�t�����g�� VLAN ID (x)�@�@�@�@�@�@ > " -nonewline -foregroundcolor yellow
    $fvlan = read-host
}
$fipaddress = ($fipandsubnet -split "/")[0]
$fsubnetmask = ($fipandsubnet -split "/")[1]

message-step "�o�b�N���l�b�g���[�N�̍\��������͂��Ă��������B"
$bipandsubnet = ""
$bvlan = ""
while (-not ($bipandsubnet -match "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$")) {
    write-host "> " -nonewline -foregroundcolor green
    write-host "�o�b�N�� IP �A�h���X (x.x.x.x/x) �@> " -nonewline -foregroundcolor yellow
    $bipandsubnet = read-host
}
while (-not ($bvlan -match "^[0-9]{1,4}")) {
    write-host "> " -nonewline -foregroundcolor green
    write-host "�o�b�N�� VLAN ID (x)�@�@�@�@�@�@�@ > " -nonewline -foregroundcolor yellow
    $bvlan = read-host
}
$bipaddress = ($bipandsubnet -split "/")[0]
$bsubnetmask = ($bipandsubnet -split "/")[1]

if ($hbnum -ge 1) {
    message-step "�n�[�g�r�[�g�l�b�g���[�N (1) �̍\��������͂��Ă��������B"
    $hb1ipandsubnet = ""
    $hb1vlan = ""
    while (-not ($hb1ipandsubnet -match "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$")) {
        write-host "> " -nonewline -foregroundcolor green
        write-host "�n�[�g�r�[�g (1) IP �A�h���X (x.x.x.x/x) �@> " -nonewline -foregroundcolor yellow
        $hb1ipandsubnet = read-host
    }
    while (-not ($hb1vlan -match "^[0-9]{1,4}")) {
        write-host "> " -nonewline -foregroundcolor green
        write-host "�n�[�g�r�[�g (1) VLAN ID (x)�@�@�@�@�@�@�@ > " -nonewline -foregroundcolor yellow
        $hb1vlan = read-host
    }
    $hb1ipaddress = ($hb1ipandsubnet -split "/")[0]
    $hb1subnetmask = ($hb1ipandsubnet -split "/")[1]
} 

if ($hbnum -ge 2) {
    message-step "�n�[�g�r�[�g�l�b�g���[�N (2) �̍\��������͂��Ă��������B"
    $hb2ipandsubnet = ""
    $hb2vlan = ""
    while (-not ($hb2ipandsubnet -match "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$")) {
        write-host "> " -nonewline -foregroundcolor green
        write-host "�n�[�g�r�[�g (2) IP �A�h���X (x.x.x.x/x) �@> " -nonewline -foregroundcolor yellow
        $hb2ipandsubnet = read-host
    }
    while (-not ($hb2vlan -match "^[0-9]{1,4}")) {
        write-host "> " -nonewline -foregroundcolor green
        write-host "�n�[�g�r�[�g (2) VLAN ID (x)�@�@�@�@�@�@�@ > " -nonewline -foregroundcolor yellow
        $hb2vlan = read-host
    }
    $hb2ipaddress = ($hb2ipandsubnet -split "/")[0]
    $hb2subnetmask = ($hb2ipandsubnet -split "/")[1]
} 

message-step "�f�t�H���g�Q�[�g�E�F�C��ݒ肷��C���^�t�F�C�X��I�����Ă��������B"
write-host ""
write-host "�@�@1 ) �t�����g��"
write-host "�@�@2 ) �o�b�N��"
write-host ""
$defgwifnum = ""
while (-not ($defgwifnum -match "^[1-2]$")) {
    write-host "> " -nonewline -foregroundcolor green
    write-host "�C���^�t�F�C�X (1-2) > " -nonewline -foregroundcolor yellow
    $defgwifnum = read-host
}

message-step "�f�t�H���g�Q�[�g�E�F�C�̏�����͂��Ă�������"
$defgwipaddress = ""
while (-not ($defgwipaddress -match "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$")) {
    write-host "> " -nonewline -foregroundcolor green
    write-host "�f�t�H���g�Q�[�g�E�F�C (x.x.x.x) > " -nonewline -foregroundcolor yellow
    $defgwipaddress = read-host
}

message-step "�ȉ��̍\���Ńl�b�g���[�N���\�����܂��B"
write-host "> " -nonewline -foregroundcolor green
write-host "�t�����g�� IP �A�h���X�@�@�@> " -nonewline -foregroundcolor yellow
$fipaddress
write-host "> " -nonewline -foregroundcolor green
write-host "�t�����g�� �T�u�l�b�g�}�X�N > " -nonewline -foregroundcolor yellow
$fsubnetmask
write-host "> " -nonewline -foregroundcolor green
write-host "�t�����g�� VLAN ID�@�@�@�@�@> " -nonewline -foregroundcolor yellow
$fvlan
write-host "> " -nonewline -foregroundcolor green
write-host "�o�b�N�� IP �A�h���X�@�@�@�@> " -nonewline -foregroundcolor yellow
$bipaddress
write-host "> " -nonewline -foregroundcolor green
write-host "�o�b�N�� �T�u�l�b�g�}�X�N�@ > " -nonewline -foregroundcolor yellow
$bsubnetmask
write-host "> " -nonewline -foregroundcolor green
write-host "�o�b�N�� VLAN ID�@�@�@�@�@�@> " -nonewline -foregroundcolor yellow
$bvlan

if ($hbnum -ge 1) {
    write-host "> " -nonewline -foregroundcolor green
    write-host "�n�[�g�r�[�g (1) IP �A�h���X�@�@�@> " -nonewline -foregroundcolor yellow
    $hb1ipaddress
    write-host "> " -nonewline -foregroundcolor green
    write-host "�n�[�g�r�[�g (1) �T�u�l�b�g�}�X�N > " -nonewline -foregroundcolor yellow
    $hb1subnetmask
    write-host "> " -nonewline -foregroundcolor green
    write-host "�n�[�g�r�[�g (1) VLAN ID�@�@�@�@�@> " -nonewline -foregroundcolor yellow
    $hb1vlan
} 

if ($hbnum -ge 2) {
    write-host "> " -nonewline -foregroundcolor green
    write-host "�n�[�g�r�[�g (2) IP �A�h���X�@�@�@> " -nonewline -foregroundcolor yellow
    $hb2ipaddress
    write-host "> " -nonewline -foregroundcolor green
    write-host "�n�[�g�r�[�g (2) �T�u�l�b�g�}�X�N > " -nonewline -foregroundcolor yellow
    $hb2subnetmask
    write-host "> " -nonewline -foregroundcolor green
    write-host "�n�[�g�r�[�g (2) VLAN ID�@�@�@�@�@> " -nonewline -foregroundcolor yellow
    $hb2vlan
} 

write-host "> " -nonewline -foregroundcolor green
write-host "�f�t�H���g�Q�[�g�E�F�C�C���^�t�F�C�X > " -nonewline -foregroundcolor yellow
("�t�����g��", "�o�b�N��")[([int]$defgwifnum) - 1]
write-host "> " -nonewline -foregroundcolor green
write-host "�f�t�H���g�Q�[�g�E�F�C IP �A�h���X�@ > " -nonewline -foregroundcolor yellow
$defgwipaddress

wait-yninput

message-stepstart "�`�[�~���O�f�o�C�X Front �� VLAN �C���^�t�F�C�X���쐬���܂�"
set-netlbfoteamnic -name "Front" -vlanid $fvlan -confirm:$false | out-null
message-stepresult $?

message-stepstart "�`�[�~���O�f�o�C�X Back �� VLAN �C���^�t�F�C�X���쐬���܂�"
set-netlbfoteamnic -name "Back" -vlanid $bvlan -confirm:$false | out-null
message-stepresult $?

if ($hbnum -ge 1) {
    message-stepstart "�`�[�~���O�f�o�C�X HB1 �� VLAN �C���^�t�F�C�X���쐬���܂�"
    set-netlbfoteamnic -name "HB1" -vlanid $hb1vlan -confirm:$false | out-null
    message-stepresult $?
} 

if ($hbnum -ge 2) {
    message-stepstart "�`�[�~���O�f�o�C�X HB2 �� VLAN �C���^�t�F�C�X���쐬���܂�"
    set-netlbfoteamnic -name "HB2" -vlanid $hb2vlan -confirm:$false | out-null
    message-stepresult $?
} 

# �V�����f�o�C�X����ۑ�
$fteamname = "Front - VLAN $fvlan"
$bteamname = "Back - VLAN $bvlan"
$hb1teamname = "HB1 - VLAN $hb1vlan"
$hb2teamname = "HB2 - VLAN $hb2vlan"

if ($defgwifnum -eq 1) {
    message-stepstart "�`�[�~���O�f�o�C�X Front �� IP �A�h���X�ƃQ�[�g�E�F�C��ݒ肵�܂�"
    get-netadapter -name $fteamname | new-netipaddress -ipaddress $fipaddress -prefixlength $fsubnetmask -defaultgateway $defgwipaddress -confirm:$false | out-null
    message-stepresult $?

    message-stepstart "�`�[�~���O�f�o�C�X Back �� IP �A�h���X��ݒ肵�܂�"
    get-netadapter -name $bteamname | new-netipaddress -ipaddress $bipaddress -prefixlength $bsubnetmask -confirm:$false | out-null
    message-stepresult $?
} else {
    message-stepstart "�`�[�~���O�f�o�C�X Front �� IP �A�h���X��ݒ肵�܂�"
    get-netadapter -name $fteamname | new-netipaddress -ipaddress $fipaddress -prefixlength $fsubnetmask -confirm:$false | out-null
    message-stepresult $?

    message-stepstart "�`�[�~���O�f�o�C�X Back �� IP �A�h���X�ƃQ�[�g�E�F�C��ݒ肵�܂�"
    get-netadapter -name $bteamname | new-netipaddress -ipaddress $bipaddress -prefixlength $bsubnetmask -defaultgateway $defgwipaddress -confirm:$false | out-null
    message-stepresult $?
}

if ($hbnum -ge 1) {
    message-stepstart "�`�[�~���O�f�o�C�X HB1 �� IP �A�h���X��ݒ肵�܂�"
    get-netadapter -name $hb1teamname | new-netipaddress -ipaddress $hb1ipaddress -prefixlength $hb1subnetmask -confirm:$false | out-null
    message-stepresult $?
} 

if ($hbnum -ge 2) {
    message-stepstart "�`�[�~���O�f�o�C�X HB2 �� IP �A�h���X��ݒ肵�܂�"
    get-netadapter -name $hb2teamname | new-netipaddress -ipaddress $hb2ipaddress -prefixlength $hb2subnetmask -confirm:$false | out-null
    message-stepresult $?
} 

message-step "IP �A�h���X�̍\�����m�F���Ă��������B"
get-netipaddress | where {$_.interfacealias -match "^Front|^Back|^LAN|^HB"} | where {$_.addressfamily -eq "IPv4"} | sort interfacealias | select interfacealias, ipaddress, prefixlength | format-table

message-step "�f�t�H���g�Q�[�g�E�F�C�̍\�����m�F���Ă��������B"
$defroute = get-netroute -destinationprefix "0.0.0.0/0"
$ifi = $defroute.ifindex
$ifn = (get-netadapter -ifindex $ifi).name

$newdefroute = "" | select InterfaceName, DestinationPrefix, NextHop
$newdefroute.interfacename = $ifn
$newdefroute.destinationprefix = $defroute.destinationprefix
$newdefroute.nexthop = $defroute.nexthop
$newdefroute

write-host ""
wait-yinput

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
invoke-nextscript -script (join-path $myinvocation.mycommand.path "..\..\install-05_set_route.bat")
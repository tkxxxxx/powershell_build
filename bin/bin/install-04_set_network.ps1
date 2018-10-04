# 初期化処理 ===================================================================
# モジュールの読み込み
foreach ($func in (get-childitem (join-path $myinvocation.mycommand.path "..\func_*"))) {
	import-module $func
}

# タイトルを表示
show-title "ネットワークの設定"

# メイン処理 ===================================================================
# 確認メッセージの表示
message-step "現在接続されている NIC の名前を以下の通り変更します。"
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

message-stepstart "NIC の名前を変更します"
$res = $true

foreach ($nic in $newnics) {
    rename-netadapter -name $nic.oldname -newname $nic.newname
    if (-not $?) {
        $res = $false
    }
}
message-stepresult $res

message-step "設定するハートビートネットワークの数を入力してください。"
$hbnum = ""
while (-not ($hbnum -match "^[0-2]$")) {
    write-host "> " -nonewline -foregroundcolor green
    write-host "ハートビート数 (0-2) > " -nonewline -foregroundcolor yellow
    $hbnum = read-host
}

message-step "以下のメンバでチーミングデバイスを作成します"
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

message-stepstart "チーミングデバイス Front を作成します"
new-netlbfoteam -name "Front" -teammembers ("LAN 1", "LAN 2") -teamingmode switchindependent -loadbalancingalgorithm dynamic -confirm:$false | out-null
message-stepresult $?

message-stepstart "チーミングデバイス Front の LAN 2 をスタンバイアダプタに指定します"
set-netlbfoteammember -name "LAN 2" -administrativemode standby -confirm:$false | out-null
message-stepresult $?

message-stepstart "チーミングデバイス Back を作成します"
new-netlbfoteam -name "Back" -teammembers ("LAN 3", "LAN 4") -teamingmode switchindependent -loadbalancingalgorithm dynamic -confirm:$false | out-null
message-stepresult $?

message-stepstart "チーミングデバイス Back の LAN 4 をスタンバイアダプタに指定します"
set-netlbfoteammember -name "LAN 4" -administrativemode standby -confirm:$false | out-null
message-stepresult $?

if ($hbnum -eq 1) {
    message-stepstart "チーミングデバイス HB1 を作成します"
    new-netlbfoteam -name "HB1" -teammembers ("LAN 5", "LAN 6") -teamingmode switchindependent -loadbalancingalgorithm dynamic -confirm:$false | out-null
    message-stepresult $?

    message-stepstart "チーミングデバイス HB1 の LAN 6 をスタンバイアダプタに指定します"
    set-netlbfoteammember -name "LAN 6" -administrativemode standby -confirm:$false | out-null
    message-stepresult $?
} 

if ($hbnum -eq 2) {
    message-stepstart "チーミングデバイス HB1 を作成します"
    new-netlbfoteam -name "HB1" -teammembers "LAN 5" -teamingmode switchindependent -loadbalancingalgorithm dynamic -confirm:$false | out-null
    message-stepresult $?

    message-stepstart "チーミングデバイス HB2 を作成します"
    new-netlbfoteam -name "HB2" -teammembers "LAN 6" -teamingmode switchindependent -loadbalancingalgorithm dynamic -confirm:$false | out-null
    message-stepresult $?
} 

message-step "作成されたチーミングデバイスを確認してください。"
get-netlbfoteam | select name, members, teamingmode, loadbalancingalgorithm | sort name | format-table
wait-yninput

message-step "作成されたチーミングデバイスのメンバを確認してください。"
get-netlbfoteammember | select team, name, administrativemode | sort name | format-table
wait-yninput


message-step "フロント側ネットワークの構成情報を入力してください"
$fipandsubnet = ""
$fvlan = ""
while (-not ($fipandsubnet -match "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$")) {
    write-host "> " -nonewline -foregroundcolor green
    write-host "フロント側 IP アドレス (x.x.x.x/x) > " -nonewline -foregroundcolor yellow
    $fipandsubnet = read-host
}
while (-not ($fvlan -match "^[0-9]{1,4}")) {
    write-host "> " -nonewline -foregroundcolor green
    write-host "フロント側 VLAN ID (x)　　　　　　 > " -nonewline -foregroundcolor yellow
    $fvlan = read-host
}
$fipaddress = ($fipandsubnet -split "/")[0]
$fsubnetmask = ($fipandsubnet -split "/")[1]

message-step "バック側ネットワークの構成情報を入力してください。"
$bipandsubnet = ""
$bvlan = ""
while (-not ($bipandsubnet -match "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$")) {
    write-host "> " -nonewline -foregroundcolor green
    write-host "バック側 IP アドレス (x.x.x.x/x) 　> " -nonewline -foregroundcolor yellow
    $bipandsubnet = read-host
}
while (-not ($bvlan -match "^[0-9]{1,4}")) {
    write-host "> " -nonewline -foregroundcolor green
    write-host "バック側 VLAN ID (x)　　　　　　　 > " -nonewline -foregroundcolor yellow
    $bvlan = read-host
}
$bipaddress = ($bipandsubnet -split "/")[0]
$bsubnetmask = ($bipandsubnet -split "/")[1]

if ($hbnum -ge 1) {
    message-step "ハートビートネットワーク (1) の構成情報を入力してください。"
    $hb1ipandsubnet = ""
    $hb1vlan = ""
    while (-not ($hb1ipandsubnet -match "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$")) {
        write-host "> " -nonewline -foregroundcolor green
        write-host "ハートビート (1) IP アドレス (x.x.x.x/x) 　> " -nonewline -foregroundcolor yellow
        $hb1ipandsubnet = read-host
    }
    while (-not ($hb1vlan -match "^[0-9]{1,4}")) {
        write-host "> " -nonewline -foregroundcolor green
        write-host "ハートビート (1) VLAN ID (x)　　　　　　　 > " -nonewline -foregroundcolor yellow
        $hb1vlan = read-host
    }
    $hb1ipaddress = ($hb1ipandsubnet -split "/")[0]
    $hb1subnetmask = ($hb1ipandsubnet -split "/")[1]
} 

if ($hbnum -ge 2) {
    message-step "ハートビートネットワーク (2) の構成情報を入力してください。"
    $hb2ipandsubnet = ""
    $hb2vlan = ""
    while (-not ($hb2ipandsubnet -match "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$")) {
        write-host "> " -nonewline -foregroundcolor green
        write-host "ハートビート (2) IP アドレス (x.x.x.x/x) 　> " -nonewline -foregroundcolor yellow
        $hb2ipandsubnet = read-host
    }
    while (-not ($hb2vlan -match "^[0-9]{1,4}")) {
        write-host "> " -nonewline -foregroundcolor green
        write-host "ハートビート (2) VLAN ID (x)　　　　　　　 > " -nonewline -foregroundcolor yellow
        $hb2vlan = read-host
    }
    $hb2ipaddress = ($hb2ipandsubnet -split "/")[0]
    $hb2subnetmask = ($hb2ipandsubnet -split "/")[1]
} 

message-step "デフォルトゲートウェイを設定するインタフェイスを選択してください。"
write-host ""
write-host "　　1 ) フロント側"
write-host "　　2 ) バック側"
write-host ""
$defgwifnum = ""
while (-not ($defgwifnum -match "^[1-2]$")) {
    write-host "> " -nonewline -foregroundcolor green
    write-host "インタフェイス (1-2) > " -nonewline -foregroundcolor yellow
    $defgwifnum = read-host
}

message-step "デフォルトゲートウェイの情報を入力してください"
$defgwipaddress = ""
while (-not ($defgwipaddress -match "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$")) {
    write-host "> " -nonewline -foregroundcolor green
    write-host "デフォルトゲートウェイ (x.x.x.x) > " -nonewline -foregroundcolor yellow
    $defgwipaddress = read-host
}

message-step "以下の構成でネットワークを構成します。"
write-host "> " -nonewline -foregroundcolor green
write-host "フロント側 IP アドレス　　　> " -nonewline -foregroundcolor yellow
$fipaddress
write-host "> " -nonewline -foregroundcolor green
write-host "フロント側 サブネットマスク > " -nonewline -foregroundcolor yellow
$fsubnetmask
write-host "> " -nonewline -foregroundcolor green
write-host "フロント側 VLAN ID　　　　　> " -nonewline -foregroundcolor yellow
$fvlan
write-host "> " -nonewline -foregroundcolor green
write-host "バック側 IP アドレス　　　　> " -nonewline -foregroundcolor yellow
$bipaddress
write-host "> " -nonewline -foregroundcolor green
write-host "バック側 サブネットマスク　 > " -nonewline -foregroundcolor yellow
$bsubnetmask
write-host "> " -nonewline -foregroundcolor green
write-host "バック側 VLAN ID　　　　　　> " -nonewline -foregroundcolor yellow
$bvlan

if ($hbnum -ge 1) {
    write-host "> " -nonewline -foregroundcolor green
    write-host "ハートビート (1) IP アドレス　　　> " -nonewline -foregroundcolor yellow
    $hb1ipaddress
    write-host "> " -nonewline -foregroundcolor green
    write-host "ハートビート (1) サブネットマスク > " -nonewline -foregroundcolor yellow
    $hb1subnetmask
    write-host "> " -nonewline -foregroundcolor green
    write-host "ハートビート (1) VLAN ID　　　　　> " -nonewline -foregroundcolor yellow
    $hb1vlan
} 

if ($hbnum -ge 2) {
    write-host "> " -nonewline -foregroundcolor green
    write-host "ハートビート (2) IP アドレス　　　> " -nonewline -foregroundcolor yellow
    $hb2ipaddress
    write-host "> " -nonewline -foregroundcolor green
    write-host "ハートビート (2) サブネットマスク > " -nonewline -foregroundcolor yellow
    $hb2subnetmask
    write-host "> " -nonewline -foregroundcolor green
    write-host "ハートビート (2) VLAN ID　　　　　> " -nonewline -foregroundcolor yellow
    $hb2vlan
} 

write-host "> " -nonewline -foregroundcolor green
write-host "デフォルトゲートウェイインタフェイス > " -nonewline -foregroundcolor yellow
("フロント側", "バック側")[([int]$defgwifnum) - 1]
write-host "> " -nonewline -foregroundcolor green
write-host "デフォルトゲートウェイ IP アドレス　 > " -nonewline -foregroundcolor yellow
$defgwipaddress

wait-yninput

message-stepstart "チーミングデバイス Front に VLAN インタフェイスを作成します"
set-netlbfoteamnic -name "Front" -vlanid $fvlan -confirm:$false | out-null
message-stepresult $?

message-stepstart "チーミングデバイス Back に VLAN インタフェイスを作成します"
set-netlbfoteamnic -name "Back" -vlanid $bvlan -confirm:$false | out-null
message-stepresult $?

if ($hbnum -ge 1) {
    message-stepstart "チーミングデバイス HB1 に VLAN インタフェイスを作成します"
    set-netlbfoteamnic -name "HB1" -vlanid $hb1vlan -confirm:$false | out-null
    message-stepresult $?
} 

if ($hbnum -ge 2) {
    message-stepstart "チーミングデバイス HB2 に VLAN インタフェイスを作成します"
    set-netlbfoteamnic -name "HB2" -vlanid $hb2vlan -confirm:$false | out-null
    message-stepresult $?
} 

# 新しいデバイス名を保存
$fteamname = "Front - VLAN $fvlan"
$bteamname = "Back - VLAN $bvlan"
$hb1teamname = "HB1 - VLAN $hb1vlan"
$hb2teamname = "HB2 - VLAN $hb2vlan"

if ($defgwifnum -eq 1) {
    message-stepstart "チーミングデバイス Front に IP アドレスとゲートウェイを設定します"
    get-netadapter -name $fteamname | new-netipaddress -ipaddress $fipaddress -prefixlength $fsubnetmask -defaultgateway $defgwipaddress -confirm:$false | out-null
    message-stepresult $?

    message-stepstart "チーミングデバイス Back に IP アドレスを設定します"
    get-netadapter -name $bteamname | new-netipaddress -ipaddress $bipaddress -prefixlength $bsubnetmask -confirm:$false | out-null
    message-stepresult $?
} else {
    message-stepstart "チーミングデバイス Front に IP アドレスを設定します"
    get-netadapter -name $fteamname | new-netipaddress -ipaddress $fipaddress -prefixlength $fsubnetmask -confirm:$false | out-null
    message-stepresult $?

    message-stepstart "チーミングデバイス Back に IP アドレスとゲートウェイを設定します"
    get-netadapter -name $bteamname | new-netipaddress -ipaddress $bipaddress -prefixlength $bsubnetmask -defaultgateway $defgwipaddress -confirm:$false | out-null
    message-stepresult $?
}

if ($hbnum -ge 1) {
    message-stepstart "チーミングデバイス HB1 に IP アドレスを設定します"
    get-netadapter -name $hb1teamname | new-netipaddress -ipaddress $hb1ipaddress -prefixlength $hb1subnetmask -confirm:$false | out-null
    message-stepresult $?
} 

if ($hbnum -ge 2) {
    message-stepstart "チーミングデバイス HB2 に IP アドレスを設定します"
    get-netadapter -name $hb2teamname | new-netipaddress -ipaddress $hb2ipaddress -prefixlength $hb2subnetmask -confirm:$false | out-null
    message-stepresult $?
} 

message-step "IP アドレスの構成を確認してください。"
get-netipaddress | where {$_.interfacealias -match "^Front|^Back|^LAN|^HB"} | where {$_.addressfamily -eq "IPv4"} | sort interfacealias | select interfacealias, ipaddress, prefixlength | format-table

message-step "デフォルトゲートウェイの構成を確認してください。"
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
    message-step "ping を確認する場合は IP アドレス、終了する場合は q を入力します。"
    write-host "> " -nonewline -foregroundcolor green
    write-host "宛先 IP アドレス (x.x.x.x, q) > " -nonewline -foregroundcolor yellow
    $ping = read-host

    if ($ping -match "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$") {
        
        $cmd = "ping $ping"
        invoke-expression $cmd
    }
}

write-host ""
# 後続スクリプトの呼び出し
invoke-nextscript -script (join-path $myinvocation.mycommand.path "..\..\install-05_set_route.bat")
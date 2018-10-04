# 初期化処理 ===================================================================
# モジュールの読み込み
foreach ($func in (get-childitem (join-path $myinvocation.mycommand.path "..\func_*"))) {
	import-module $func
}

# タイトルを表示
show-title "静的ルートの設定"

# メイン処理 ===================================================================
# デフォルトゲートウェイが居ないインタフェイスを確認
$defroute = get-netroute -destinationprefix "0.0.0.0/0"
$ifi = $defroute.ifindex
if ($ifi -eq (get-netadapter -name "Front*").ifindex) {
    $routeif = (get-netadapter -name "Back*").ifindex
} else {
    $routeif = (get-netadapter -name "Front*").ifindex
}

$destnw = ""
while (-not ($destnw -match "^[Qq]$")) {
    message-step "現在のルーティングテーブルを表示します。"
    get-netroute -addressfamily ipv4 | where {$_.nexthop -ne "0.0.0.0"} | select destinationprefix, nexthop | format-table

    message-step "ルートを追加する場合はルート情報、終了する場合は q を入力します。"
    write-host "> " -nonewline -foregroundcolor green
    write-host "ネットワークアドレス (x.x.x.x/x, q) > " -nonewline -foregroundcolor yellow
    $destnw = read-host

    if ($destnw -match "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$") {
        
        $destgw = ""
        while (-not ($destgw -match "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$")) {
            write-host "> " -nonewline -foregroundcolor green
            write-host "ゲートウェイ (x.x.x.x)　　　　　　　> " -nonewline -foregroundcolor yellow
            $destgw = read-host
        }

        message-step "以下の静的ルートを追加します。"
        write-host "> " -nonewline -foregroundcolor green
        write-host "ルート > " -nonewline -foregroundcolor yellow
        write-host "$destnw via $destgw"
        write-host ""
        wait-yninput

        message-stepstart "静的ルートを追加します"
        new-netroute -destinationprefix $destnw -interfaceindex $routeif -nexthop $destgw -confirm:$false | out-null
        message-stepresult $?

    }
}


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
invoke-nextscript -script (join-path $myinvocation.mycommand.path "..\..\install-06_reboot.bat")
# 初期化処理 ===================================================================
# モジュールの読み込み
foreach ($func in (get-childitem (join-path $myinvocation.mycommand.path "..\func_*"))) {
	import-module $func
}

# タイトルを表示
show-title "Sysprep の実行"

# メイン処理 ===================================================================

# Sysprep 実行の確認
$input = ""
while (-not ($input -match "^[YyNn]$")) {
    write-host "> " -nonewline -foregroundcolor green
    write-host "Sysprepを実行しますか (Y/N) > " -nonewline -foregroundcolor yellow
    $input = read-host
    
    if ($input -match "^[Nn]") {
        write-host "Sysprepの実行がキャンセルされました > " -nonewline -foregroundcolor yellow
        write-host ""
        invoke-nextscript -script (join-path $myinvocation.mycommand.path "..\..\install-03_set_hostname.bat")
    }
    
    if ($input -match "^[Yy]") {
    # Sysprep 実行後の準備
    message-stepstart "後続処理の再起動後の自動実行を登録します"
    register-runonce -name "aftersysprep" -command "move C:\nssol C:\Users\Administrator\Desktop\script & start `"`" C:\Users\Administrator\Desktop\script\install-02_post_sysprep.bat"
    message-stepresult $?

    # Sysprep の実行
    message-step "Sysprep を実行します。"
    message-alert "Sysprep を実行すると、ホストの構成情報が初期化されます。" "続行すると、ホストが自動で再起動されます。" "再起動後、ウィザードにしたがって構成を完了してください。" "構成の完了後、次のスクリプトが自動で起動するまでお待ちください。"
    $cmd = "C:\Windows\System32\Sysprep\sysprep.exe /quiet /generalize /oobe /reboot"
    invoke-expression $cmd
    }
}

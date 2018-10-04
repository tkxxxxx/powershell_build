# 初期化処理 ===================================================================
# モジュールの読み込み
foreach ($func in (get-childitem (join-path $myinvocation.mycommand.path "..\func_*"))) {
	import-module $func
}

# タイトルを表示
show-title "再起動"

# メイン処理 ===================================================================

# 再起動後の処理の登録
message-stepstart "再起動後の後続処理の自動実行を登録します"
register-runonce -name "aftersysprep" -command "start `"`" C:\Users\Administrator\Desktop\script\install-07_install_powerpath.bat"
message-stepresult $?

# 再起動後の自動ログオンの設定
message-stepstart "再起動後の自動ログオンを一時的に有効化しています"
enable-autologon
message-stepresult $?

message-step "OS を再起動します。"
write-host ""
wait-yninput

restart-computer -confirm:$false

exit
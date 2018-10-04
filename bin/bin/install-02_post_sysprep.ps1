# 初期化処理 ===================================================================
# モジュールの読み込み
foreach ($func in (get-childitem (join-path $myinvocation.mycommand.path "..\func_*"))) {
	import-module $func
}

# タイトルを表示
show-title "Sysprep 後のクリーニング"

# メイン処理 ===================================================================

message-stepstart "自動起動処理の登録を解除します"
unregister-runonce
message-stepresult $?

# 後続スクリプトの呼び出し
invoke-nextscript -script (join-path $myinvocation.mycommand.path "..\..\install-03_set_hostname.bat")
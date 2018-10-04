# 初期化処理 ===================================================================
# モジュールの読み込み
foreach ($func in (get-childitem (join-path $myinvocation.mycommand.path "..\func_*"))) {
	import-module $func
}

# タイトルを表示
show-title "ホスト名の変更"

# メイン処理 ===================================================================
# 確認メッセージの表示
	write-host "設定するホスト名を入力してください。"

# 想定パタンに一致するまで無限ループ
$input = ""
while (-not ($input -match "^[a-zA-Z0-9-]{1,15}$")) {
    write-host "> " -nonewline -foregroundcolor green
    write-host "ホスト名 > " -nonewline -foregroundcolor yellow
    $input = read-host
}

message-step "ホスト名を変更します。"
wait-yninput

message-stepstart "ホスト名を変更しています"
rename-computer $input 3>&1 | out-null
message-stepresult $?

# 後続スクリプトの呼び出し
invoke-nextscript -script (join-path $myinvocation.mycommand.path "..\..\install-04_set_network.bat")
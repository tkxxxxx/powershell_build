# 初期化処理 ===================================================================
# モジュールの読み込み
foreach ($func in (get-childitem (join-path $myinvocation.mycommand.path "..\func_*"))) {
	import-module $func
}

# タイトルを表示
show-title "準備"

# メイン処理 ===================================================================

# 全ファイルをローカルにコピー
$targetdir = "C:\nssol"
message-stepstart "必要なファイル群をローカルにコピィします"
copy-item -recurse .\bin $targetdir
message-stepresult $?

# 後続スクリプトの呼び出し
invoke-nextscript -script "C:\nssol\install-01_sysprep.bat"

# 初期化処理 ===================================================================
# モジュールの読み込み
foreach ($func in (get-childitem (join-path $myinvocation.mycommand.path "..\func_*"))) {
	import-module $func
}

# タイトルを表示
show-title "その他の設定"

# メイン処理 ===================================================================

message-stepstart "リモートデスクトップを有効にします"
(get-wmiobject -class Win32_TerminalServiceSetting -namespace root\cimv2\terminalservices).setallowtsconnections(1, 1) | out-null
message-stepresult $?

message-stepstart "リモートデスクトップの NLA を無効化します"
(get-wmiobject -class Win32_TSGeneralSetting -namespace root\cimv2\terminalservices -filter "TerminalName='RDP-tcp'").setuserauthenticationrequired(0) | out-null
message-stepresult $?

message-stepstart "Windows ファイアウォールを無効化します"
get-netfirewallprofile | set-netfirewallprofile -enabled false
message-stepresult $?

message-stepstart "ドライブの最適化スケジュールを無効にします。"
get-scheduledtask -taskpath "\Microsoft\Windows\Defrag\" | disable-scheduledtask | out-null
message-stepresult $?


# message-stepstart "DSET を配置します"
# if (-not (test-path "C:\Program Files (x86)\Dell")) {
#     new-item "C:\Program Files (x86)\Dell" -type directory | out-null
# }
# if (-not (test-path "C:\Program Files (x86)\Dell\Dell_DSET_3.7.0.219.exe")) {
#     copy-item "C:\Users\Administrator\Desktop\script\bin\Dell_DSET_3.7.0.219.exe" "C:\Program Files (x86)\Dell" | out-null
# }
# message-stepresult $?

write-host ""
message-confirm "すべての処理が完了しました。"
exit
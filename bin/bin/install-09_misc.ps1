# ���������� ===================================================================
# ���W���[���̓ǂݍ���
foreach ($func in (get-childitem (join-path $myinvocation.mycommand.path "..\func_*"))) {
	import-module $func
}

# �^�C�g����\��
show-title "���̑��̐ݒ�"

# ���C������ ===================================================================

message-stepstart "�����[�g�f�X�N�g�b�v��L���ɂ��܂�"
(get-wmiobject -class Win32_TerminalServiceSetting -namespace root\cimv2\terminalservices).setallowtsconnections(1, 1) | out-null
message-stepresult $?

message-stepstart "�����[�g�f�X�N�g�b�v�� NLA �𖳌������܂�"
(get-wmiobject -class Win32_TSGeneralSetting -namespace root\cimv2\terminalservices -filter "TerminalName='RDP-tcp'").setuserauthenticationrequired(0) | out-null
message-stepresult $?

message-stepstart "Windows �t�@�C�A�E�H�[���𖳌������܂�"
get-netfirewallprofile | set-netfirewallprofile -enabled false
message-stepresult $?

message-stepstart "�h���C�u�̍œK���X�P�W���[���𖳌��ɂ��܂��B"
get-scheduledtask -taskpath "\Microsoft\Windows\Defrag\" | disable-scheduledtask | out-null
message-stepresult $?


# message-stepstart "DSET ��z�u���܂�"
# if (-not (test-path "C:\Program Files (x86)\Dell")) {
#     new-item "C:\Program Files (x86)\Dell" -type directory | out-null
# }
# if (-not (test-path "C:\Program Files (x86)\Dell\Dell_DSET_3.7.0.219.exe")) {
#     copy-item "C:\Users\Administrator\Desktop\script\bin\Dell_DSET_3.7.0.219.exe" "C:\Program Files (x86)\Dell" | out-null
# }
# message-stepresult $?

write-host ""
message-confirm "���ׂĂ̏������������܂����B"
exit
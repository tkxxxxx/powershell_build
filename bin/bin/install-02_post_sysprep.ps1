# ���������� ===================================================================
# ���W���[���̓ǂݍ���
foreach ($func in (get-childitem (join-path $myinvocation.mycommand.path "..\func_*"))) {
	import-module $func
}

# �^�C�g����\��
show-title "Sysprep ��̃N���[�j���O"

# ���C������ ===================================================================

message-stepstart "�����N�������̓o�^���������܂�"
unregister-runonce
message-stepresult $?

# �㑱�X�N���v�g�̌Ăяo��
invoke-nextscript -script (join-path $myinvocation.mycommand.path "..\..\install-03_set_hostname.bat")
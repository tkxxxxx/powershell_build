# ���������� ===================================================================
# ���W���[���̓ǂݍ���
foreach ($func in (get-childitem (join-path $myinvocation.mycommand.path "..\func_*"))) {
	import-module $func
}

# �^�C�g����\��
show-title "�ċN��"

# ���C������ ===================================================================

# �ċN����̏����̓o�^
message-stepstart "�ċN����̌㑱�����̎������s��o�^���܂�"
register-runonce -name "aftersysprep" -command "start `"`" C:\Users\Administrator\Desktop\script\install-07_install_powerpath.bat"
message-stepresult $?

# �ċN����̎������O�I���̐ݒ�
message-stepstart "�ċN����̎������O�I�����ꎞ�I�ɗL�������Ă��܂�"
enable-autologon
message-stepresult $?

message-step "OS ���ċN�����܂��B"
write-host ""
wait-yninput

restart-computer -confirm:$false

exit
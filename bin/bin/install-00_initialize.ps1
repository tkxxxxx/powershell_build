# ���������� ===================================================================
# ���W���[���̓ǂݍ���
foreach ($func in (get-childitem (join-path $myinvocation.mycommand.path "..\func_*"))) {
	import-module $func
}

# �^�C�g����\��
show-title "����"

# ���C������ ===================================================================

# �S�t�@�C�������[�J���ɃR�s�[
$targetdir = "C:\nssol"
message-stepstart "�K�v�ȃt�@�C���Q�����[�J���ɃR�s�B���܂�"
copy-item -recurse .\bin $targetdir
message-stepresult $?

# �㑱�X�N���v�g�̌Ăяo��
invoke-nextscript -script "C:\nssol\install-01_sysprep.bat"

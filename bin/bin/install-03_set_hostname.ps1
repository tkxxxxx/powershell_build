# ���������� ===================================================================
# ���W���[���̓ǂݍ���
foreach ($func in (get-childitem (join-path $myinvocation.mycommand.path "..\func_*"))) {
	import-module $func
}

# �^�C�g����\��
show-title "�z�X�g���̕ύX"

# ���C������ ===================================================================
# �m�F���b�Z�[�W�̕\��
	write-host "�ݒ肷��z�X�g������͂��Ă��������B"

# �z��p�^���Ɉ�v����܂Ŗ������[�v
$input = ""
while (-not ($input -match "^[a-zA-Z0-9-]{1,15}$")) {
    write-host "> " -nonewline -foregroundcolor green
    write-host "�z�X�g�� > " -nonewline -foregroundcolor yellow
    $input = read-host
}

message-step "�z�X�g����ύX���܂��B"
wait-yninput

message-stepstart "�z�X�g����ύX���Ă��܂�"
rename-computer $input 3>&1 | out-null
message-stepresult $?

# �㑱�X�N���v�g�̌Ăяo��
invoke-nextscript -script (join-path $myinvocation.mycommand.path "..\..\install-04_set_network.bat")
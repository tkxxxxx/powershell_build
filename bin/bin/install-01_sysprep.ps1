# ���������� ===================================================================
# ���W���[���̓ǂݍ���
foreach ($func in (get-childitem (join-path $myinvocation.mycommand.path "..\func_*"))) {
	import-module $func
}

# �^�C�g����\��
show-title "Sysprep �̎��s"

# ���C������ ===================================================================

# Sysprep ���s�̊m�F
$input = ""
while (-not ($input -match "^[YyNn]$")) {
    write-host "> " -nonewline -foregroundcolor green
    write-host "Sysprep�����s���܂��� (Y/N) > " -nonewline -foregroundcolor yellow
    $input = read-host
    
    if ($input -match "^[Nn]") {
        write-host "Sysprep�̎��s���L�����Z������܂��� > " -nonewline -foregroundcolor yellow
        write-host ""
        invoke-nextscript -script (join-path $myinvocation.mycommand.path "..\..\install-03_set_hostname.bat")
    }
    
    if ($input -match "^[Yy]") {
    # Sysprep ���s��̏���
    message-stepstart "�㑱�����̍ċN����̎������s��o�^���܂�"
    register-runonce -name "aftersysprep" -command "move C:\nssol C:\Users\Administrator\Desktop\script & start `"`" C:\Users\Administrator\Desktop\script\install-02_post_sysprep.bat"
    message-stepresult $?

    # Sysprep �̎��s
    message-step "Sysprep �����s���܂��B"
    message-alert "Sysprep �����s����ƁA�z�X�g�̍\����񂪏���������܂��B" "���s����ƁA�z�X�g�������ōċN������܂��B" "�ċN����A�E�B�U�[�h�ɂ��������č\�����������Ă��������B" "�\���̊�����A���̃X�N���v�g�������ŋN������܂ł��҂����������B"
    $cmd = "C:\Windows\System32\Sysprep\sysprep.exe /quiet /generalize /oobe /reboot"
    invoke-expression $cmd
    }
}

# �������O�I����L��������
function Enable-AutoLogon {
    param (
        $u = "Administrator",
        $p = "@bs0nne!"
    )

    $regkeypath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    $regkey = get-itemproperty $regkeypath

    if ($regkey.AutoAdminLogon -eq $null) {
        new-itemproperty -path $regkeypath -name "AutoAdminLogon" -propertytype dword -value 1 | out-null
    } else {
        set-itemproperty -path $regkeypath -name "AutoAdminLogon" -value 1 | out-null
    }

    if ($regkey.DefaultUserName -eq $null) {
        new-itemproperty -path $regkeypath -name "DefaultUserName" -propertytype string -value "$u" | out-null
    } else {
        set-itemproperty -path $regkeypath -name "DefaultUserName" -value "$u" | out-null
    }

    if ($regkey.DefaultPassword -eq $null) {
        new-itemproperty -path $regkeypath -name "DefaultPassword" -propertytype string -value "$p" | out-null
    } else {
        set-itemproperty -path $regkeypath -name "DefaultPassword" -value "$p" | out-null
    }
}

# �������O�I���𖳌�������
function Disable-AutoLogon {

    $regkeypath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    $regkey = get-itemproperty $regkeypath
    
    if ($regkey.AutoAdminLogon -ne $null) {
        remove-itemproperty -path $regkeypath -name "AutoAdminLogon"
    }

    if ($regkey.DefaultUserName -ne $null) {
        remove-itemproperty -path $regkeypath -name "DefaultUserName"
    }

    if ($regkey.DefaultPassword -ne $null ) {
        remove-itemproperty -path $regkeypath -name "DefaultPassword"
    }
}

# ���O�I�����̎������s�R�}���h��o�^����
function Register-RunOnce {
    
    param (
        [parameter(mandatory = $true)] $name,
        [parameter(mandatory = $true)] $command
    )

    $startupdir = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"
    $startupfile = join-path $startupdir ("AKD-WIN_" + $name + ".bat")

    write-output "@echo off" | set-content -encoding default $startupfile
    write-output $command  | add-content -encoding default $startupfile
    write-output "del %0"  | add-content -encoding default $startupfile
}

# ���O�I�����̎������s�R�}���h���폜����
function Unregister-RunOnce {
    
    $startupdir = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"
    $startupfile = join-path $startupdir "AKD-WIN_*"
    
    remove-item $startupfile -force
}

# �X�N���v�g�����s����
function Execute-Script {
    param (
        [parameter(mandatory = $true)] $script
    )

    start-process -filepath C:\Windows\System32\cmd.exe -argumentlist "/c start `"`" $script"
}

# ���̃X�N���v�g�ɐi��
function Invoke-NextScript {
    param (
        [parameter(mandatory = $true)] $script,
        $description = "�����Ď��̃X�N���v�g�����s���܂��B"
    )
    
    message-step "$description"
    wait-yinput
    execute-script -script "$script"
}

# �^�C�g����\������
function Show-Title {
	param (
		$title
	)
	
	write-host "AKD-WIN" -nonewline -foregroundcolor green
	write-host " : " -nonewline
	write-host "$title" -foregroundcolor yellow
	write-host "--"
}

# �����J�n�̃��b�Z�[�W��\������
function Message-Step {
	param (
		$message
	)
	
	write-host ""
	write-host "*" -nonewline -foregroundcolor green
	write-host " $message"
}

# �����J�n�̃��b�Z�[�W��\������
function Message-StepStart {
	param (
		$message
	)
	
	write-host ""
	write-host "*" -nonewline -foregroundcolor green
	write-host " $message ... " -nonewline
}

# �������ʂ�\������
function Message-StepResult {
	param (
		$result
	)
	
	if ($result) {
		write-host "����" -foregroundcolor green
	} else {
		write-host "�����Ɏ��s���܂����B" -foregroundcolor red
		wait-yinput "�I������ɂ� Y ����͂��Ă�������"
		exit
	}
}

# ���[�U�� Y/N �̓��͂�҂�
function Wait-YNInput {

    # �z��p�^���Ɉ�v����܂Ŗ������[�v
    $input = ""
    while (-not ($input -match "^[YyNn]$")) {
    	write-host "> " -nonewline -foregroundcolor green
        write-host "���s���Ă�낵���ł����H (Y/N) > " -nonewline -foregroundcolor yellow
    	$input = read-host
    }
        
    if ($input -match "[Nn]") {
        write-host "���f����܂����B" -foregroundcolor red
        wait-yinput "�I������ɂ� Y ����͂��Ă�������"
        exit
    }
}

# ���[�U�� Y �̓��͂�҂�
function Wait-YInput {
    param (
        $message = "���s����ɂ� Y ����͂��Ă�������"
    )
    
    $input = ""
    while (-not ($input -match "^[Yy]$")) {
    	write-host "> " -nonewline -foregroundcolor green
        write-host "$message > " -nonewline -foregroundcolor yellow
    	$input = read-host
    }
}

# ���[�U�̃L�[���͂�҂�
function Wait-Input {
    param (
        $message = "���s����ɂ͉����L�[�������Ă������� ... "
    )
    
	write-host "> " -nonewline -foregroundcolor green
	write-host "$message" -nonewline -foregroundcolor yellow
	[console]::readkey() | out-null
}

# �x�����b�Z�[�W��\�����đҋ@����
function Message-Alert {
	write-host ""
	write-host "= �x�� ========================================================================" -foregroundcolor red
	
	foreach ($message in $args) {
		write-host "�@$message" -foregroundcolor yellow
	}
	
	wait-yninput
}

# �m�F���b�Z�[�W��\�����đҋ@����
function Message-Confirm {
	write-host ""
	write-host "= �m�F ========================================================================" -foregroundcolor green
	
	foreach ($message in $args) {
		write-host "�@$message"
	}
	
	wait-yinput
}





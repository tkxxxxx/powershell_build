# 自動ログオンを有効化する
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

# 自動ログオンを無効化する
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

# ログオン時の自動実行コマンドを登録する
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

# ログオン時の自動実行コマンドを削除する
function Unregister-RunOnce {
    
    $startupdir = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"
    $startupfile = join-path $startupdir "AKD-WIN_*"
    
    remove-item $startupfile -force
}

# スクリプトを実行する
function Execute-Script {
    param (
        [parameter(mandatory = $true)] $script
    )

    start-process -filepath C:\Windows\System32\cmd.exe -argumentlist "/c start `"`" $script"
}

# 次のスクリプトに進む
function Invoke-NextScript {
    param (
        [parameter(mandatory = $true)] $script,
        $description = "続けて次のスクリプトを実行します。"
    )
    
    message-step "$description"
    wait-yinput
    execute-script -script "$script"
}

# タイトルを表示する
function Show-Title {
	param (
		$title
	)
	
	write-host "AKD-WIN" -nonewline -foregroundcolor green
	write-host " : " -nonewline
	write-host "$title" -foregroundcolor yellow
	write-host "--"
}

# 処理開始のメッセージを表示する
function Message-Step {
	param (
		$message
	)
	
	write-host ""
	write-host "*" -nonewline -foregroundcolor green
	write-host " $message"
}

# 処理開始のメッセージを表示する
function Message-StepStart {
	param (
		$message
	)
	
	write-host ""
	write-host "*" -nonewline -foregroundcolor green
	write-host " $message ... " -nonewline
}

# 処理結果を表示する
function Message-StepResult {
	param (
		$result
	)
	
	if ($result) {
		write-host "完了" -foregroundcolor green
	} else {
		write-host "処理に失敗しました。" -foregroundcolor red
		wait-yinput "終了するには Y を入力してください"
		exit
	}
}

# ユーザの Y/N の入力を待つ
function Wait-YNInput {

    # 想定パタンに一致するまで無限ループ
    $input = ""
    while (-not ($input -match "^[YyNn]$")) {
    	write-host "> " -nonewline -foregroundcolor green
        write-host "続行してよろしいですか？ (Y/N) > " -nonewline -foregroundcolor yellow
    	$input = read-host
    }
        
    if ($input -match "[Nn]") {
        write-host "中断されました。" -foregroundcolor red
        wait-yinput "終了するには Y を入力してください"
        exit
    }
}

# ユーザの Y の入力を待つ
function Wait-YInput {
    param (
        $message = "続行するには Y を入力してください"
    )
    
    $input = ""
    while (-not ($input -match "^[Yy]$")) {
    	write-host "> " -nonewline -foregroundcolor green
        write-host "$message > " -nonewline -foregroundcolor yellow
    	$input = read-host
    }
}

# ユーザのキー入力を待つ
function Wait-Input {
    param (
        $message = "続行するには何かキーを押してください ... "
    )
    
	write-host "> " -nonewline -foregroundcolor green
	write-host "$message" -nonewline -foregroundcolor yellow
	[console]::readkey() | out-null
}

# 警告メッセージを表示して待機する
function Message-Alert {
	write-host ""
	write-host "= 警告 ========================================================================" -foregroundcolor red
	
	foreach ($message in $args) {
		write-host "　$message" -foregroundcolor yellow
	}
	
	wait-yninput
}

# 確認メッセージを表示して待機する
function Message-Confirm {
	write-host ""
	write-host "= 確認 ========================================================================" -foregroundcolor green
	
	foreach ($message in $args) {
		write-host "　$message"
	}
	
	wait-yinput
}





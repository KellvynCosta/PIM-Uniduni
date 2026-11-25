param([string]$DeviceId)
$ErrorActionPreference = 'Stop'
$flutterBin = Join-Path $env:USERPROFILE 'dev\flutter\bin\flutter.bat'
$adbBin = Join-Path $env:USERPROFILE 'AppData\Local\Android\Sdk\platform-tools\adb.exe'
if (!(Test-Path -LiteralPath $flutterBin)) { throw 'Flutter não encontrado na pasta dev\flutter do usuário.' }
if (!(Test-Path -LiteralPath $adbBin)) { throw 'Instale o Android SDK e Platform-Tools pelo Android Studio antes de executar no Samsung.' }
Invoke-RestMethod 'http://127.0.0.1:5288/api/Produtos' -TimeoutSec 10 | Out-Null
if (!$DeviceId) {
    $connected = @(& $adbBin devices | Select-String '^([^\s]+)\s+device$' | ForEach-Object { $_.Matches[0].Groups[1].Value })
    if ($connected.Count -ne 1) { throw 'Conecte e autorize um único aparelho por USB, ou informe -DeviceId.' }
    $DeviceId = $connected[0]
}
& $adbBin -s $DeviceId reverse tcp:5288 tcp:5288
if ($LASTEXITCODE -ne 0) { throw 'Não foi possível conectar o aparelho à API por USB.' }
Push-Location (Join-Path $PSScriptRoot 'mobile')
try { & $flutterBin run -d $DeviceId --dart-define=API_URL=http://127.0.0.1:5288 }
finally { Pop-Location }

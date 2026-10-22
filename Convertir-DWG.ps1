# PANORAMA LAB / TraficLabPro DWG Version Switch v1.0
# Local-only conversion using the user's own licensed AutoCAD Core Console.
# No third-party binaries are embedded or distributed.
[CmdletBinding()]
param(
  [string[]]$InputPaths = @(),
  [ValidateSet('2018','2013','2010','2007','2004','2000','R14')][string]$Target = '2013',
  [string]$OutputDir = '',
  [switch]$Headless
)
$ErrorActionPreference = 'Stop'
$VersionCode = @{
  'R14'='AC1014'; '2000'='AC1015'; '2004'='AC1018';
  '2007'='AC1021'; '2010'='AC1024'; '2013'='AC1027'; '2018'='AC1032'
}
$Formats = @{
  'AC1009'='R12'; 'AC1012'='R13'; 'AC1014'='R14'; 'AC1015'='2000';
  'AC1018'='2004'; 'AC1021'='2007'; 'AC1024'='2010';
  'AC1027'='2013'; 'AC1032'='2018-2027'
}
function Find-CoreConsole {
  $base = [Environment]::GetFolderPath('ProgramFiles')
  $autodesk = Join-Path $base 'Autodesk'
  if (-not (Test-Path -LiteralPath $autodesk)) { return $null }
  $paths = @(Get-ChildItem -LiteralPath $autodesk -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '^AutoCAD\s+(20\d{2})$' } |
    Sort-Object { [int]([regex]::Match($_.Name,'20\d{2}').Value) } -Descending)
  foreach ($folder in $paths) {
    $exe = Join-Path $folder.FullName 'accoreconsole.exe'
    if (Test-Path -LiteralPath $exe) {
      return @{ exe=$exe; year=[int]([regex]::Match($folder.Name,'20\d{2}').Value) }
    }
  }
  return $null
}
function Read-DwgCode([string]$File) {
  if (-not ([IO.File]::Exists($File))) { throw ('No existe el archivo: ' + $File) }
  if ([IO.Path]::GetExtension($File).ToLowerInvariant() -ne '.dwg') { throw 'Solo se admite DWG' }
  $stream = [IO.File]::Open($File,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
  try {
    if ($stream.Length -lt 6) { throw 'DWG incompleto' }
    $bytes=New-Object byte[] 6
    if ($stream.Read($bytes,0,6) -ne 6) { throw 'No se pudo leer la cabecera' }
    $code=[Text.Encoding]::ASCII.GetString($bytes)
    if (-not $Formats.ContainsKey($code)) { throw ('Version DWG no reconocida: ' + $code) }
    return $code
  } finally { $stream.Dispose() }
}
function As-LispPath([string]$path) {
  $x=$path.Replace('\','/')
  if ($x.Contains('"') -or $x.Contains([char]10)) { throw 'Ruta de trabajo no admitida' }
  return ('"' + $x + '"')
}
function Run-Core([string]$exe,[string]$drawingPath,[string]$script,[string]$folder,[string]$step) {
  $stdout=Join-Path $folder ($step + '-stdout.txt')
  $stderr=Join-Path $folder ($step + '-stderr.txt')
  $cliArgs='/i "'+$drawingPath+'" /s "'+$script+'" /l en-US'
  $process=Start-Process -FilePath $exe -ArgumentList $cliArgs -WorkingDirectory $folder -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr
  try {
    if (-not $process.WaitForExit(240000)) {
      try { $process.Kill() } catch {}
      throw ('AutoCAD excedio el tiempo para ' + $step)
    }
    $process.Refresh()
    if (($null -ne $process.ExitCode) -and ($process.ExitCode -ne 0)) {
      $tail=''
      if (Test-Path $stdout) { $tail=([IO.File]::ReadAllText($stdout,[Text.Encoding]::Unicode) -replace '[\x00-\x1F]+',' ').Trim() }
      throw ('AutoCAD fallo en '+$step+': exit '+$process.ExitCode+' '+$tail)
    }
  } finally { $process.Dispose() }
}
function Convert-One([string]$file,[string]$target,[string]$destination,$engine) {
  $temp=$null
  $before=$null
  try {
    $full=[IO.Path]::GetFullPath($file)
    $code=Read-DwgCode $full
    if ($engine.year -lt 2018 -and $target -eq '2018') { throw 'AutoCAD 2018 o superior es necesario para generar DWG 2018' }
    $before=(Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash.ToLowerInvariant()
    $temp=Join-Path ([IO.Path]::GetTempPath()) ('PanoramaDwg-' + [Guid]::NewGuid().ToString('N'))
    [IO.Directory]::CreateDirectory($temp) | Out-Null
    $source=Join-Path $temp 'source.dwg'
    $output=Join-Path $temp 'converted.dwg'
    $saveScript=Join-Path $temp 'convert.scr'
    $openScript=Join-Path $temp 'reopen.scr'
    $audit=Join-Path $temp 'reopen.pass'
    [IO.File]::Copy($full,$source,$false)
    if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToLowerInvariant() -ne $before) { throw 'Copia temporal no coincide con el original' }
    $lispOut=As-LispPath $output
    $lispAudit=As-LispPath $audit
    $lines=@(
      '(setvar "CMDECHO" 0)',
      '(setvar "FILEDIA" 0)',
      '(setvar "CMDDIA" 0)',
      '(setvar "EXPERT" 5)',
      '(setq src_ok (= (strcase (getvar "DWGNAME")) "SOURCE.DWG"))',
      ('(if src_ok (command "_.SAVEAS" "' + $target + '" ' + $lispOut + '))'),
      '(princ)'
    )
    [IO.File]::WriteAllLines($saveScript,$lines,[Text.Encoding]::ASCII)
    Run-Core $engine.exe $source $saveScript $temp 'save'
    if (-not (Test-Path -LiteralPath $output)) { throw 'AutoCAD no genero archivo de salida' }
    if ((Get-Item -LiteralPath $output).Length -lt 100) { throw 'Archivo de salida vacio' }
    $outputCode=Read-DwgCode $output
    if ($outputCode -ne $VersionCode[$target]) {
      throw ('Formato no coincide: solicitado '+$VersionCode[$target]+', obtenido '+$outputCode)
    }
    $verifyLines=@(
      '(setvar "CMDECHO" 0)',
      ('(setq ver_f (open '+$lispAudit+' "w"))'),
      '(if ver_f (progn (write-line (getvar "DWGNAME") ver_f) (close ver_f)))',
      '(princ)'
    )
    [IO.File]::WriteAllLines($openScript,$verifyLines,[Text.Encoding]::ASCII)
    Run-Core $engine.exe $output $openScript $temp 'reopen'
    if (-not (Test-Path -LiteralPath $audit)) { throw 'No hay evidencia de reapertura' }
    $qa=[IO.File]::ReadAllText($audit).Trim()
    if ($qa -ne 'converted.dwg') { throw ('Reapertura inesperada: '+$qa) }
    if ((Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash.ToLowerInvariant() -ne $before) { throw 'ALERTA: el original cambio durante el proceso' }
    [IO.Directory]::CreateDirectory($destination) | Out-Null
    $stem=[IO.Path]::GetFileNameWithoutExtension($full)
    $name=$stem+'__DWG'+$target
    $dest=Join-Path $destination ($name+'.dwg')
    $i=2
    while ([IO.File]::Exists($dest)) {
      $dest=Join-Path $destination ($name+'__'+$i+'.dwg')
      $i++
    }
    [IO.File]::Copy($output,$dest,$false)
    if ((Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash.ToLowerInvariant() -ne
        (Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash.ToLowerInvariant()) {
      throw 'La copia final no coincide'
    }
    return [pscustomobject]@{
      ok=$true; file=[IO.Path]::GetFileName($full); sourceCode=$code; target=$target;
      output=[IO.Path]::GetFileName($dest); sourceSha256=$before;
      outputSha256=(Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash.ToLowerInvariant();
      reopened=$true; sourceUnchanged=$true;
      warning='Apertura validada; NO garantiza conservacion de XREF, proxy, bloques especializados o compatibilidad semantica integral'
    }
  } catch {
    return [pscustomobject]@{ ok=$false; file=[IO.Path]::GetFileName($file); target=$target; error=$_.Exception.Message }
  } finally {
    if ($temp -and (Test-Path -LiteralPath $temp)) {
      try { [IO.Directory]::Delete($temp,$true) } catch {}
    }
  }
}
function Run-Batch([string[]]$paths,[string]$target,[string]$folder,$engine) {
  [IO.Directory]::CreateDirectory($folder) | Out-Null
  $results=@()
  foreach($file in $paths) {
    Write-Host ('Procesando: '+[IO.Path]::GetFileName($file))
    $result=Convert-One $file $target $folder $engine
    $results+= $result
    Write-Host ($result | ConvertTo-Json -Compress -Depth 4)
  }
  $stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
  $report=Join-Path $folder ('INFORME_DWG_'+$stamp+'.json')
  $manifest=[pscustomobject]@{
    tool='TraficLabPro DWG Version Switch'; version='1.0'; createdAt=(Get-Date).ToUniversalTime().ToString('o');
    target=$target; files=$results; passed=@($results | Where-Object { $_.ok }).Count;
    failed=@($results | Where-Object { -not $_.ok }).Count;
    scope='Validation of DWG header and successful AutoCAD reopening only. No global drawing equivalence certificate.'
  }
  [IO.File]::WriteAllText($report,($manifest | ConvertTo-Json -Depth 6),[Text.Encoding]::UTF8)
  return $manifest
}
$engine=Find-CoreConsole
if ($Headless) {
  if (-not $engine) { Write-Error 'AutoCAD Core Console no instalado'; exit 2 }
  if ($InputPaths.Count -lt 1) { Write-Error 'Falta -InputPaths'; exit 2 }
  if (-not $OutputDir) { $OutputDir=Join-Path ([Environment]::GetFolderPath('Desktop')) 'DWG_CONVERTIDOS' }
  $result=Run-Batch $InputPaths $Target $OutputDir $engine
  Write-Host ('QA: '+$result.passed+' correctos; '+$result.failed+' errores.')
  if ($result.failed -gt 0) { exit 1 }
  exit 0
}
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()
$form=New-Object Windows.Forms.Form
$form.Text='TraficLabPro | Conversor DWG'
$form.Size=New-Object Drawing.Size(760,590)
$form.MinimumSize=New-Object Drawing.Size(710,560)
$form.StartPosition='CenterScreen'
$form.Font=New-Object Drawing.Font('Segoe UI',10)
$form.BackColor=[Drawing.Color]::FromArgb(245,245,242)
$hdr=New-Object Windows.Forms.Label
$hdr.Text='CONVERSOR DE VERSIONES DWG'
$hdr.Font=New-Object Drawing.Font('Segoe UI',17,[Drawing.FontStyle]::Bold)
$hdr.Location=New-Object Drawing.Point(25,20)
$hdr.AutoSize=$true
$form.Controls.Add($hdr)
$sub=New-Object Windows.Forms.Label
$sub.Text='Gratis. Local. Tus planos no se suben a Internet.'
$sub.Location=New-Object Drawing.Point(27,64)
$sub.Size=New-Object Drawing.Size(700,28)
$form.Controls.Add($sub)
$engineInfo=New-Object Windows.Forms.Label
$engineInfo.Location=New-Object Drawing.Point(27,98)
$engineInfo.Size=New-Object Drawing.Size(680,26)
if($engine){$engineInfo.Text='Motor: AutoCAD '+$engine.year+' detectado en este equipo'}
else {$engineInfo.Text='Motor no encontrado: necesitas AutoCAD de escritorio con Core Console.';$engineInfo.ForeColor=[Drawing.Color]::DarkRed}
$form.Controls.Add($engineInfo)
$files=@()
$choose=New-Object Windows.Forms.Button
$choose.Text='1. Seleccionar archivos DWG'
$choose.Location=New-Object Drawing.Point(27,134)
$choose.Size=New-Object Drawing.Size(280,39)
$choose.Add_Click({
  $dialog=New-Object Windows.Forms.OpenFileDialog
  $dialog.Filter='Dibujos AutoCAD (*.dwg)|*.dwg'
  $dialog.Multiselect=$true
  if($dialog.ShowDialog() -eq [Windows.Forms.DialogResult]::OK){
    $script:files=@($dialog.FileNames)
    $selected.Items.Clear()
    foreach($f in $script:files){[void]$selected.Items.Add([IO.Path]::GetFileName($f))}
    $state.Text=($script:files.Count.ToString()+' archivos seleccionados')
  }
})
$form.Controls.Add($choose)
$selected=New-Object Windows.Forms.ListBox
$selected.Location=New-Object Drawing.Point(27,186)
$selected.Size=New-Object Drawing.Size(680,112)
$selected.Anchor='Top,Left,Right'
$form.Controls.Add($selected)
$targetLabel=New-Object Windows.Forms.Label
$targetLabel.Text='2. Version de destino:'
$targetLabel.Location=New-Object Drawing.Point(27,313)
$targetLabel.AutoSize=$true
$form.Controls.Add($targetLabel)
$combo=New-Object Windows.Forms.ComboBox
$combo.DropDownStyle='DropDownList'
$combo.Location=New-Object Drawing.Point(210,309)
$combo.Size=New-Object Drawing.Size(155,34)
foreach($v in @('2018','2013','2010','2007','2004','2000','R14')) { [void]$combo.Items.Add($v) }
$combo.SelectedItem='2013'
$form.Controls.Add($combo)
$destination=Join-Path ([Environment]::GetFolderPath('Desktop')) 'DWG_CONVERTIDOS'
$outLabel=New-Object Windows.Forms.Label
$outLabel.Location=New-Object Drawing.Point(27,354)
$outLabel.Size=New-Object Drawing.Size(665,28)
$outLabel.Text='Salida: Escritorio\DWG_CONVERTIDOS (nunca sobrescribe)'
$form.Controls.Add($outLabel)
$run=New-Object Windows.Forms.Button
$run.Text='3. CONVERTIR Y VERIFICAR'
$run.Location=New-Object Drawing.Point(27,400)
$run.Size=New-Object Drawing.Size(355,46)
$run.BackColor=[Drawing.Color]::FromArgb(255,122,43)
$run.FlatStyle='Flat'
$run.Add_Click({
  if(-not $engine){ [Windows.Forms.MessageBox]::Show('Instala o abre AutoCAD de escritorio. No se incluye AutoCAD en esta descarga.','Motor requerido') | Out-Null; return }
  if($script:files.Count -lt 1){ [Windows.Forms.MessageBox]::Show('Primero elige archivos DWG.','Sin archivos') | Out-Null; return }
  $run.Enabled=$false
  $state.Text='Procesando con AutoCAD...'
  $form.Refresh()
  [Windows.Forms.Application]::DoEvents()
  try {
    $res=Run-Batch $script:files $combo.SelectedItem.ToString() $destination $engine
    $state.Text=($res.passed.ToString()+' convertidos; '+$res.failed.ToString()+' errores. Revisa el informe local.')
    [Windows.Forms.MessageBox]::Show($state.Text+' Los originales se conservaron.','Conversion finalizada') | Out-Null
    Start-Process explorer.exe $destination
  } catch {
    $state.Text=('Error: '+$_.Exception.Message)
    [Windows.Forms.MessageBox]::Show($state.Text,'Conversion') | Out-Null
  } finally { $run.Enabled=$true }
})
$form.Controls.Add($run)
$state=New-Object Windows.Forms.Label
$state.Location=New-Object Drawing.Point(27,463)
$state.Size=New-Object Drawing.Size(690,45)
$state.Text='Listo para trabajar. Haz primero una copia de seguridad de tus planos importantes.'
$form.Controls.Add($state)
$warning=New-Object Windows.Forms.Label
$warning.Text='ADVERTENCIA: Bloques dinamicos, proxies, XREF y objetos verticales pueden cambiar al guardar a formatos antiguos. Revisa siempre la entrega.'
$warning.ForeColor=[Drawing.Color]::FromArgb(115,63,23)
$warning.Location=New-Object Drawing.Point(27,508)
$warning.Size=New-Object Drawing.Size(687,45)
$warning.Font=New-Object Drawing.Font('Segoe UI',8)
$form.Controls.Add($warning)
[void]$form.ShowDialog()

<#Begin Header#>
#requires -version 3
<#
.SYNOPSIS
  Compares two file checksums but only the first n bytes and last n bytes. 
.DESCRIPTION
  The idea of this script is to prompt for two files and then compare them based on two calculations, the checksum of the first n bytes and the last n bytes
  For files smaller than n*2 bytes, this is a waste of cpu cycles, you can just compare them straight up with any checksum tool and it will run faster.
  For files larger than n*2 bytes, first a warning, this should not be used for critical functions, we are not testing the entire file, we are sampling the file and running a checksum on the samples
  The idea is if you set $ByteSize = 10000000, we read the first 10MB and the last 10MB of the file and compute a checksum, we then do that on the second file and compare.
  If they match we have a reasonable certainty that the files are the same, without waiting for a long checksum function to complete.
  Is it a certainty that the files match? NO!
  Do not use this on an untrusted file, this is for checking for human error such as terminating a copy before it's complete, copying the wrong file, etc.
  
.PARAMETER <Parameter_Name>
  $ByteSize can be adjusted below to change the size being read, 10MB is the default.
.INPUTS
  File selection dialog for first and second file in the compare.
.OUTPUTS
  Outputs MATCH or NO MATCH
.NOTES
  Version:        2022071801
  Author:         Phil Ellis
  Creation Date:  2022-07-18
  Purpose/Change: Initial script development
  
.EXAMPLE
  PS D:\USBBuilding> .\Cmp-Hash.ps1
  NO MATCH
#>
<#End Header#>

$ByteSize = 10000000 # 10 MB

function Read-FirstBytes {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [Alias('FullName', 'FilePath')]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]$Path,        
        
        [Parameter(Mandatory=$true, Position = 1)]
        [long]$Bytes,

        [ValidateSet('ByteArray', 'HexString', 'Base64')]
        [string]$As = 'ByteArray'
    )
    try {
        $stream = [System.IO.File]::OpenRead($Path)
        $length = [math]::Min([math]::Abs($Bytes), $stream.Length)
        $buffer = [byte[]]::new($length)
        $null   = $stream.Read($buffer, 0, $length)
        switch ($As) {
            'HexString' { ($buffer | ForEach-Object { "{0:x2}" -f $_ }) -join '' ; break }
            'Base64'    { [Convert]::ToBase64String($buffer) ; break }
            default     { ,$buffer }
        }
    }
    catch { throw }
    finally { $stream.Dispose() }
}

function Read-LastBytes {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [Alias('FullName', 'FilePath')]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]$Path,        
        
        [Parameter(Mandatory=$true, Position = 1)]
        [long]$Bytes,

        [ValidateSet('ByteArray', 'HexString', 'Base64')]
        [string]$As = 'ByteArray'
    )
    try {
        $stream = [System.IO.File]::OpenRead($Path)
        $length = [math]::Min([math]::Abs($Bytes), $stream.Length)
        $null   = $stream.Seek(-$length, 'End')
        $buffer = for ($i = 0; $i -lt $length; $i++) { $stream.ReadByte() }
        switch ($As) {
            'HexString' { ($buffer | ForEach-Object { "{0:x2}" -f $_ }) -join '' ; break }
            'Base64'    { [Convert]::ToBase64String($buffer) ; break }
            default     { ,[Byte[]]$buffer }
        }
    }
    catch { throw }
    finally { $stream.Dispose() }
}

<#Get-FileName#>
#File Dialog Prompt (title doesn't seem to work)
Function Get-FileName($initialDirectory, $diagTitle, $filter)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
	$OpenFileDialog.filter = "$filter"
    $OpenFileDialog.Title = "$diagTitle"
	$OpenFileDialog.ShowDialog() | Out-Null
	$OpenFileDialog.filename
}
#Example
#$filenametest = Get-FileName "c:\temp" "Select a file" "txt files (*.txt)|*.txt|All files (*.*)|*.*"
#$filename

$file1 = Get-FileName "$PSScriptRoot" "Select the first file" "All files (*.*)|*.*"
$file2 = Get-FileName "$PSScriptRoot" "Select the second file" "All files (*.*)|*.*"


$begin = Read-FirstBytes -Path "$file1" -Bytes $ByteSize    # take the first n bytes
$end   = Read-LastBytes -Path "$file1" -Bytes $ByteSize   # and the last n bytes

$Algorithm = 'MD5'
$hash  = [Security.Cryptography.HashAlgorithm]::Create($Algorithm)
$hashValue = $hash.ComputeHash($begin + $end)

$file1hash = ($hashValue  | ForEach-Object { "{0:x2}" -f $_ }) -join ''



$begin = Read-FirstBytes -Path "$file2" -Bytes $ByteSize    # take the first n bytes
$end   = Read-LastBytes -Path "$file2" -Bytes $ByteSize   # and the last n bytes

$Algorithm = 'MD5'
$hash  = [Security.Cryptography.HashAlgorithm]::Create($Algorithm)
$hashValue = $hash.ComputeHash($begin + $end)

$file2hash = ($hashValue  | ForEach-Object { "{0:x2}" -f $_ }) -join ''

if ( -not (Compare-Object -ReferenceObject $file1hash -DifferenceObject $file2hash)){
    write-host "MATCH"
} else {
    write-host "NO MATCH"
}
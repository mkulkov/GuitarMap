param([Parameter(Mandatory)][string]$Preset, [switch]$Release, [switch]$Plan)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
. 'C:\dev\Godot\tools\godot-build-policy.ps1'
Invoke-GodotExport -Project $root -Preset $Preset -Release:$Release -Plan:$Plan
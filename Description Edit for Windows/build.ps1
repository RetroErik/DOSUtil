[CmdletBinding()]
param([ValidateSet('Debug', 'Release')][string] $Configuration = 'Release')

$ErrorActionPreference = 'Stop'
$solution = Join-Path $PSScriptRoot 'DescriptionEditForWindows.sln'
$tests = Join-Path $PSScriptRoot 'tests\DescriptionEditForWindows.Tests\DescriptionEditForWindows.Tests.csproj'

& dotnet build $solution -c $Configuration -p:Platform=x64
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& dotnet run --project $tests -c $Configuration --no-build -p:Platform=x64
exit $LASTEXITCODE

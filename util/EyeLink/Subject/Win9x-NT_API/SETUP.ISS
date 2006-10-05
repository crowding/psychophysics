[InstallSHIELD Silent]
Version=v3.00.00
File=Response File

[DlgOrder]
Dlg0=Welcome-0
Dlg1=AskDestPath-0
Dlg2=SdSetupType-0
Dlg3=SdSelectFolder-0
Dlg4=SdStartCopy-0
Dlg5=SdFinishReboot-0
Count=6

[Welcome-0]
Result=1

[AskDestPath-0]
szPath=<ProgramFilesDir>\SMI\EyeLink_ExptKit
Result=1

[SdSetupType-0]
Result=301
szDir=<ProgramFilesDir>\SMI\EyeLink_ExptKit

[SdSelectFolder-0]
Result=1
szFolder=EyeLink Experiment Kit

[SdStartCopy-0]
Result=1

[SdFinishReboot-0]
Result=1
BootOption=3

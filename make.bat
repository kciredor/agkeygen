@echo off
ml /c /coff /Cp agkeygen.asm
link /subsystem:windows,4.0 agkeygen.obj resource\ag.res
del agkeygen.obj >nul

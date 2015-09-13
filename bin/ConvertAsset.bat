cd /d "%~dp0"

mkdir MyData\Models
mkdir MyData\Animation

tool\AssetImporter model Asset\bruce.FBX MyData\Models\bruce.mdl -t -na -l -cm -ct
::tool\AssetImporter model Asset\thug_01.FBX Data\Animation\thug_01.mdl -t -na -l -cm -ct

tool\AssetImporter model Asset\Stand_Idle.FBX MyData\Animation\Stand_Idle.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Stand_Idle_01.FBX MyData\Animation\Stand_Idle_01.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Stand_Idle_02.FBX MyData\Animation\Stand_Idle_02.mdl -nomodel -nm -nt

:: Locomotion
tool\AssetImporter model Asset\Walk_Forward.FBX MyData\Animation\Walk_Forward.mdl -nomodel -nm -nt

tool\AssetImporter model Asset\Turn_Left_90.FBX MyData\Animation\Turn_Left_90.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Turn_Left_180.FBX MyData\Animation\Turn_Left_180.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Turn_Right_90.FBX MyData\Animation\Turn_Right_90.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Turn_Right_180.FBX MyData\Animation\Turn_Right_180.mdl -nomodel -nm -nt

:: Attack
:: Close Forwad Attacks
tool\AssetImporter model Asset\Attack_Close_Forward_02.FBX MyData\Animation\Attack_Close_Forward_02.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Attack_Close_Forward_03.FBX MyData\Animation\Attack_Close_Forward_03.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Attack_Close_Forward_04.FBX MyData\Animation\Attack_Close_Forward_04.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Attack_Close_Forward_05.FBX MyData\Animation\Attack_Close_Forward_05.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Attack_Close_Forward_05.FBX MyData\Animation\Attack_Close_Forward_06.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Attack_Close_Forward_07.FBX MyData\Animation\Attack_Close_Forward_07.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Attack_Close_Forward_08.FBX MyData\Animation\Attack_Close_Forward_08.mdl -nomodel -nm -nt

:: Close Right Attack
tool\AssetImporter model Asset\Attack_Close_Right.FBX MyData\Animation\Attack_Close_Right.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Attack_Close_Right_01.FBX MyData\Animation\Attack_Close_Right_01.mdl -nomodel -nm -nt
:: tool\AssetImporter model Asset\Attack_Close_Right_02.FBX MyData\Animation\Attack_Close_Right_02.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Attack_Close_Right_03.FBX MyData\Animation\Attack_Close_Right_03.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Attack_Close_Right_04.FBX MyData\Animation\Attack_Close_Right_04.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Attack_Close_Right_05.FBX MyData\Animation\Attack_Close_Right_05.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Attack_Close_Right_06.FBX MyData\Animation\Attack_Close_Right_06.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Attack_Close_Right_07.FBX MyData\Animation\Attack_Close_Right_07.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Attack_Close_Right_08.FBX MyData\Animation\Attack_Close_Right_08.mdl -nomodel -nm -nt

:: Close Back Attack
tool\AssetImporter model Asset\Attack_Close_Back.FBX MyData\Animation\Attack_Close_Back.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Attack_Close_Back_01.FBX MyData\Animation\Attack_Close_Back_01.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Attack_Close_Back_02.FBX MyData\Animation\Attack_Close_Back_02.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Attack_Close_Back_03.FBX MyData\Animation\Attack_Close_Back_03.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Attack_Close_Back_04.FBX MyData\Animation\Attack_Close_Back_04.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Attack_Close_Back_05.FBX MyData\Animation\Attack_Close_Back_05.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Attack_Close_Back_06.FBX MyData\Animation\Attack_Close_Back_06.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Attack_Close_Back_07.FBX MyData\Animation\Attack_Close_Back_07.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Attack_Close_Back_08.FBX MyData\Animation\Attack_Close_Back_08.mdl -nomodel -nm -nt

:: Close Left Attack
tool\AssetImporter model Asset\Attack_Close_Left.FBX MyData\Animation\Attack_Close_Left.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Attack_Close_Left_01.FBX MyData\Animation\Attack_Close_Left_01.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Attack_Close_Left_02.FBX MyData\Animation\Attack_Close_Left_02.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Attack_Close_Left_03.FBX MyData\Animation\Attack_Close_Left_03.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Attack_Close_Left_04.FBX MyData\Animation\Attack_Close_Left_04.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Attack_Close_Left_05.FBX MyData\Animation\Attack_Close_Left_05.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Attack_Close_Left_06.FBX MyData\Animation\Attack_Close_Left_06.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Attack_Close_Left_07.FBX MyData\Animation\Attack_Close_Left_07.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Attack_Close_Left_08.FBX MyData\Animation\Attack_Close_Left_08.mdl -nomodel -nm -nt

:: Counter
tool\AssetImporter model Asset\Counter_Arm_Front_01.FBX MyData\Animation\Counter_Arm_Front_01.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Counter_Arm_Front_01_TG.FBX MyData\Animation\Counter_Arm_Front_01_TG.mdl -nomodel -nm -nt

:: Evade
tool\AssetImporter model Asset\Evade_Forward_01.FBX MyData\Animation\Evade_Forward_01.mdl -nomodel -nm -nt
tool\AssetImporter model Asset\Evade_Back_01.FBX MyData\Animation\Evade_Back_01.mdl -nomodel -nm -nt

rm MyData/Animation/*.mdl
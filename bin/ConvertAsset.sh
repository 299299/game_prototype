#!/bin/sh

mkdir MyData/Models
mkdir MyData/Animation

tool/AssetImporter model Asset/bruce.FBX MyData/Models/bruce.mdl -t -na -l -cm -ct -flipbone

tool/AssetImporter model Asset/Stand_Idle.FBX MyData/Animation/Stand_Idle.mdl -nomodel -nm -nt -flipbone
tool/AssetImporter model Asset/Stand_Idle_01.FBX MyData/Animation/Stand_Idle_01.mdl -nomodel -nm -nt -flipbone
tool/AssetImporter model Asset/Stand_Idle_02.FBX MyData/Animation/Stand_Idle_02.mdl -nomodel -nm -nt -flipbone

tool/AssetImporter model Asset/Walk_Forward.FBX MyData/Animation/Walk_Forward.mdl -nomodel -nm -nt -motion z -flipbone

tool/AssetImporter model Asset/Turn_Left_90.FBX MyData/Animation/Turn_Left_90.mdl -nomodel -nm -nt -motion r -flipbone
tool/AssetImporter model Asset/Turn_Left_180.FBX MyData/Animation/Turn_Left_180.mdl -nomodel -nm -nt -motion r -flipbone
tool/AssetImporter model Asset/Turn_Right_90.FBX MyData/Animation/Turn_Right_90.mdl -nomodel -nm -nt -motion r -flipbone
tool/AssetImporter model Asset/Turn_Right_180.FBX MyData/Animation/Turn_Right_180.mdl -nomodel -nm -nt -motion r -flipbone

tool/AssetImporter model Asset/Attack_Close_Forward_07.FBX MyData/Animation/Attack_Close_Forward_07.mdl -nomodel -nm -nt -motion z -flipbone
tool/AssetImporter model Asset/Attack_Close_Forward_08.FBX MyData/Animation/Attack_Close_Forward_08.mdl -nomodel -nm -nt -motion z -flipbone
tool/AssetImporter model Asset/Attack_Close_Left.FBX MyData/Animation/Attack_Close_Left.mdl -nomodel -nm -nt -motion rx -flipbone

tool/AssetImporter model Asset/Counter_Arm_Front_01.FBX MyData/Animation/Counter_Arm_Front_01.mdl -nomodel -nm -nt -origin xz -motion xz -flipbone
tool/AssetImporter model Asset/Counter_Arm_Front_01_TG.FBX MyData/Animation/Counter_Arm_Front_01_TG.mdl -nomodel -nm -nt -origin xzr -motion xz -flipbone

tool/AssetImporter model Asset/Evade_Forward_01.FBX MyData/Animation/Evade_Forward_01.mdl -nomodel -nm -nt -motion xz -flipbone
tool/AssetImporter model Asset/Evade_Back_01.FBX MyData/Animation/Evade_Back_01.mdl -nomodel -nm -nt -motion rxz -flipbone

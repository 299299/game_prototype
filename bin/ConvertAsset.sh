#!/bin/sh

tool/AssetImporter model Asset/bruce.FBX Data/Animation/bruce.mdl -t -na -l -cm -ct -flipbone

tool/AssetImporter model Asset/Stand_Idle.FBX Data/Animation/Stand_Idle.mdl -nomodel -nm -nt -flipbone
tool/AssetImporter model Asset/Stand_Idle_01.FBX Data/Animation/Stand_Idle_01.mdl -nomodel -nm -nt -flipbone
tool/AssetImporter model Asset/Stand_Idle_02.FBX Data/Animation/Stand_Idle_02.mdl -nomodel -nm -nt -flipbone

tool/AssetImporter model Asset/Walk_Forward.FBX Data/Animation/Walk_Forward.mdl -nomodel -nm -nt -motion z -flipbone
tool/AssetImporter model Asset/Stand_To_Walk_Left_90.FBX Data/Animation/Stand_To_Walk_Left_90.mdl -nomodel -nm -nt -motion rx -flipbone
tool/AssetImporter model Asset/Stand_To_Walk_Left_180.FBX Data/Animation/Stand_To_Walk_Left_180.mdl -nomodel -nm -nt -motion rz -flipbone
tool/AssetImporter model Asset/Stand_To_Walk_Right_90.FBX Data/Animation/Stand_To_Walk_Right_90.mdl -nomodel -nm -nt -motion rx -flipbone
tool/AssetImporter model Asset/Stand_To_Walk_Right_180.FBX Data/Animation/Stand_To_Walk_Right_180.mdl -nomodel -nm -nt -motion rz -flipbone
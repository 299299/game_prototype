enum FacialBoneType
{
    kFacial_Head,
    kFacial_Jaw,
    kFacial_Mouth_Bottom,
    kFacial_Mouth_Up,
    kFacial_EyeBall_Left,
    kFacial_EyeBall_Right,
    kFacial_EyeTop_Left,
    kFacial_EyeTop_Right,
    kFacial_EyeBottom_Left,
    kFacial_EyeBottom_Right,
};

class FacialBone
{
    FacialBone(int b_type, int b_index, const String&in name)
    {
        facial_bone_type = b_type;
        facial_index = b_index;
        bone_name = name;
    }

    int facial_bone_type;
    int facial_index;
    Node@ bone_node;
    String bone_name;
};

class FacialBoneManager
{
    Array<FacialBone@> facial_bones;

    FacialBoneManager()
    {
        facial_bones.Push(FacialBone(kFacial_Head, 43, "Bip01_Head"));
        facial_bones.Push(FacialBone(kFacial_Jaw, 16, "FcFX_Jaw"));
        facial_bones.Push(FacialBone(kFacial_Mouth_Bottom, 102, "FcFX_Mouth_07"));
        facial_bones.Push(FacialBone(kFacial_Mouth_Up, 98, "FcFX_Mouth_03"));

        facial_bones.Push(FacialBone(kFacial_EyeBall_Left, 105, "FcFX_Eye_L"));
        facial_bones.Push(FacialBone(kFacial_EyeBall_Right, 104, "FcFX_Eye_R"));

        facial_bones.Push(FacialBone(kFacial_EyeTop_Left, 75, "FcFX_EyLd_Top_L"));
        facial_bones.Push(FacialBone(kFacial_EyeTop_Right, 72, "FcFX_EyLd_Top_R"));
        facial_bones.Push(FacialBone(kFacial_EyeBottom_Left, 76, "FcFX_EyLd_Bottom_L"));
        facial_bones.Push(FacialBone(kFacial_EyeBottom_Right, 73, "FcFX_EyLd_Bottom_R"));
    }

    void LoadNode(Node@ node)
    {
        for (uint i=0; i<facial_bones.length; ++i)
        {
            facial_bones[i].bone_node = node.GetChild(facial_bones[i].bone_name, true);
        }
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        for (uint i=0; i<facial_bones.length; ++i)
        {
            debug.AddCross(facial_bones[i].bone_node.worldPosition, 0.05, GREEN, false);
        }
    }
};



String data = "[0: 122/568][1: 120/598][2: 119/628][3: 120/658][4: 124/688][5: 129/718][6: 136/748][7: 145/776][8: 156/804][9: 169/832][10: 183/858][11: 200/883][12: 218/908][13: 239/929][14: 264/945][15: 293/954][16: 322/956][17: 352/951][18: 380/941][19: 405/925][20: 428/906][21: 448/885][22: 467/861][23: 484/836][24: 498/809][25: 510/782][26: 520/753][27: 527/724][28: 533/695][29: 538/665][30: 541/635][31: 543/605][32: 544/575][33: 141/506][34: 166/475][35: 198/467][36: 232/470][37: 265/479][38: 348/476][39: 385/465][40: 423/461][41: 461/469][42: 493/502][43: 303/537][44: 301/569][45: 299/601][46: 298/633][47: 249/683][48: 276/684][49: 304/686][50: 330/683][51: 358/682][52: 169/550][53: 188/540][54: 231/538][55: 248/549][56: 228/554][57: 188/556][58: 368/547][59: 388/535][60: 435/538][61: 456/548][62: 434/554][63: 389/552][64: 167/500][65: 198/494][66: 231/495][67: 264/499][68: 349/497][69: 385/492][70: 423/490][71: 460/495][72: 210/536][73: 208/557][74: 209/547][75: 412/534][76: 411/556][77: 412/546][78: 275/543][79: 335/542][80: 253/627][81: 354/626][82: 235/661][83: 372/660][84: 223/794][85: 242/760][86: 271/740][87: 306/743][88: 339/741][89: 367/763][90: 387/793][91: 369/828][92: 342/854][93: 304/863][94: 266/856][95: 239/830][96: 235/793][97: 266/772][98: 305/768][99: 343/771][100: 375/792][101: 344/812][102: 306/821][103: 267/814][104: 209/547][105: 412/546]";

Array<Vector2> points;

Array<Vector2> ReadPoints(const String&in txt)
{
    Array<Vector2> ret;
    Vector2 v;
    int state = 0;
    String x_str, y_str;
    for (uint i=0; i<txt.length; ++i)
    {
        uint8 c = txt[i];
        if (c == ':')
        {
            state = 1;
            x_str = "";
            y_str = "";
        }
        else if (c == '/')
        {
            state = 2;
        }
        else
        {
            if (state == 1)
            {
                if (c != ' ')
                {
                    x_str.AppendUTF8(c);
                }
            }
            else if (state == 2)
            {
                y_str.AppendUTF8(c);

                if (c == ']')
                {
                    state = 0;
                    v.x = x_str.ToFloat();
                    v.y = y_str.ToFloat();
                    ret.Push(v);
                    // Print("Add pos=" + v.ToString());
                }
            }
        }
    }

    return ret;
}

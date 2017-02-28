enum FacialBoneType
{
    kFacial_ForeHead,
    kFacial_Nose,
    kFacial_Nose_Left,
    kFacial_Node_Right,
    kFacial_Jaw,
    kFacial_Mouth_Bottom,
    kFacial_Mouth_Up,
    kFacial_Mouth_Left,
    kFacial_Mouth_Right,
    kFacial_EyeBall_Left,
    kFacial_EyeBall_Right,
    kFacial_EyeTop_Left,
    kFacial_EyeTop_Right,
    kFacial_EyeBottom_Left,
    kFacial_EyeBottom_Right,
    kFacial_EyeLeft,
    kFacial_EyeRight,
};

enum FacialAttributeType
{
    kFacial_MouseOpenness,
    kFacial_EyeOpenness_Left,
    kFacial_EyeOpenness_Right,
    kFacial_EyePositionLeft_Left,
    kFacial_EyePositionRight_Left,
    kFacial_EyePositionLeft_Right,
    kFacial_EyePositionRight_Right,
};

class FacialBone
{
    FacialBone(int b_type, int b_index, const String&in name)
    {
        facial_bone_type = b_type;
        facial_index = b_index;
        bone_name = name;
    }

    void LoadNode(Node@ node)
    {
        if (!bone_name.empty)
        {
            bone_node = node.GetChild(bone_name, true);
        }
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        if (bone_node !is null)
        {
            // debug.AddCross(bone_node.worldPosition, 0.01, GREEN, false);
        }
    }

    int facial_bone_type;
    int facial_index;
    Node@ bone_node;
    String bone_name;
};

class FacialBoneManager
{
    Array<FacialBone@> facial_bones;
    Array<String> facial_animations;
    Array<float>  facial_attributes;
    Node@ face_node;

    FacialBoneManager()
    {
        facial_bones.Push(FacialBone(kFacial_Jaw, 16, "rabbit2:FcFX_Jaw"));
        facial_bones.Push(FacialBone(kFacial_Nose, 46, ""));
        facial_bones.Push(FacialBone(kFacial_Nose_Left, 83, "rabbit2:FcFX_Nose_L"));
        facial_bones.Push(FacialBone(kFacial_Node_Right, 82, "rabbit2:FcFX_Nose_R"));

        facial_bones.Push(FacialBone(kFacial_Mouth_Bottom, 102, "rabbit2:FcFX_Mouth_08"));
        facial_bones.Push(FacialBone(kFacial_Mouth_Up, 98, "rabbit2:FcFX_Mouth_010"));
        facial_bones.Push(FacialBone(kFacial_Mouth_Left, 90, "rabbit2:FcFX_Mouth_05"));
        facial_bones.Push(FacialBone(kFacial_Mouth_Right, 84, "rabbit2:FcFX_Mouth_012"));

        facial_bones.Push(FacialBone(kFacial_EyeBall_Left, 105, "rabbit2:FcFx_Eye_L"));
        facial_bones.Push(FacialBone(kFacial_EyeBall_Right, 104, "rabbit2:FcFx_Eye_R"));
        facial_bones.Push(FacialBone(kFacial_EyeTop_Left, 75, "rabbit2:FcFX_EyLd_Top_L"));
        facial_bones.Push(FacialBone(kFacial_EyeTop_Right, 72, "rabbit2:FcFX_EyLd_Top_R"));
        facial_bones.Push(FacialBone(kFacial_EyeBottom_Left, 76, "rabbit2:FcFX_EyLd_Bottom_L"));
        facial_bones.Push(FacialBone(kFacial_EyeBottom_Right, 73, "rabbit2:FcFX_EyLd_Bottom_R"));
        facial_bones.Push(FacialBone(kFacial_EyeLeft, 61, ""));
        facial_bones.Push(FacialBone(kFacial_EyeRight, 52, ""));

        facial_bones.Push(FacialBone(kFacial_ForeHead, 43, ""));
    }

    void Init(Scene@ scene)
    {
        face_node = scene.GetChild("Head", true);
        for (uint i=0; i<facial_bones.length; ++i)
        {
            facial_bones[i].LoadNode(face_node);
        }

        Array<String> boneNames = GetChildNodeNames(face_node);
        Array<String> mouthBones;
        for (uint i=0; i<boneNames.length; ++i)
        {
            if (boneNames[i].Contains("Mouth"))
                mouthBones.Push(boneNames[i]);
        }
        mouthBones.Push("rabbit2:FcFX_Jaw");

        for (uint i=0; i<mouthBones.length; ++i)
            Print(mouthBones[i]);

        Array<String> leftEyeBones;
        Array<String> rightEyeBones;
        for (uint i=0; i<boneNames.length; ++i)
        {
            if (boneNames[i].Contains("Ey") && boneNames[i].EndsWith("_L") && boneNames[i] != facial_bones[kFacial_EyeLeft].bone_name)
            {
                leftEyeBones.Push(boneNames[i]);
            }
            if (boneNames[i].Contains("Ey") && boneNames[i].EndsWith("_R") && boneNames[i] != facial_bones[kFacial_EyeRight].bone_name)
            {
                rightEyeBones.Push(boneNames[i]);
            }
        }
        Array<String> leftEyeBalls = { facial_bones[kFacial_EyeLeft].bone_name };
        Array<String> rightEyeBalls = { facial_bones[kFacial_EyeRight].bone_name };

        facial_animations.Push(CreatePoseAnimation("Models/rabbit_mouse_open.mdl", mouthBones, scene).name);
        facial_animations.Push(CreatePoseAnimation("Models/rabbit_eye_close_L.mdl", leftEyeBones, scene).name);
        facial_animations.Push(CreatePoseAnimation("Models/rabbit_eye_close_R.mdl", rightEyeBones, scene).name);
        facial_attributes.Push(0);
        facial_attributes.Push(0);
        facial_attributes.Push(0);
        facial_attributes.Push(0.5);
        facial_attributes.Push(0.5);
        facial_attributes.Push(0.5);
        facial_attributes.Push(0.5);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        for (uint i=0; i<facial_bones.length; ++i)
        {
            facial_bones[i].DebugDraw(debug);
        }
    }

    void Update(float dt)
    {
        AnimationController@ ac = face_node.GetComponent("AnimationController");

        facial_attributes[kFacial_EyePositionRight_Left] = 1.0 - facial_attributes[kFacial_EyePositionLeft_Left];
        facial_attributes[kFacial_EyePositionRight_Right] = 1.0 - facial_attributes[kFacial_EyePositionLeft_Right];

        for (uint i=0; i<facial_animations.length; ++i)
        {
            ac.Play(facial_animations[i], 0, false, 0);
            ac.SetWeight(facial_animations[i], facial_attributes[i]);
        }
    }
};

void FillAnimationWithCurrentPose(Animation@ anim, Node@ _node, const Array<String>& in boneNames)
{
    anim.RemoveAllTracks();
    for (uint i=0; i<boneNames.length; ++i)
    {
        Node@ n = _node.GetChild(boneNames[i], true);
        if (n is null)
        {
            log.Error("FillAnimationWithCurrentPose can not find bone " + boneNames[i]);
            continue;
        }
        AnimationTrack@ track = anim.CreateTrack(boneNames[i]);
        track.channelMask = CHANNEL_POSITION | CHANNEL_ROTATION;
        AnimationKeyFrame kf;
        kf.time = 0.0f;
        kf.position = n.position;
        kf.rotation = n.rotation;
        track.AddKeyFrame(kf);
    }
}

Animation@ CreatePoseAnimation(const String&in modelName, const Array<String>&in boneNames, Scene@ scene)
{
    Model@ model = cache.GetResource("Model", modelName);
    if (model is null)
        return null;

    Node@ n = scene.CreateChild("Temp_Node");
    AnimatedModel@ am = n.CreateComponent("AnimatedModel");
    am.model = model;

    Animation@ anim = Animation();
    anim.name = modelName + "_ani";
    FillAnimationWithCurrentPose(anim, n, boneNames);
    cache.AddManualResource(anim);
    n.Remove();

    return anim;
}

Array<String> GetChildNodeNames(Node@ node)
{
    Array<String> nodeNames;
    nodeNames.Push(node.name);

    Array<Node@> children = node.GetChildren(true);
    for (uint i=0; i<children.length; ++i)
    {
        nodeNames.Push(children[i].name);
    }

    return nodeNames;
}


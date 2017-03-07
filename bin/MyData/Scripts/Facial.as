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
    Node@ rotate_bone_node;

    float yaw = 0;
    float pitch = 0;
    float roll = 0;

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
        String rotate_bone_name = "rabbit2:Bip01_Head";
        rotate_bone_node = face_node.GetChild(rotate_bone_name, true);
        AnimatedModel@ am = face_node.GetComponent("AnimatedModel");
        Bone@ b = am.skeleton.GetBone(rotate_bone_name);
        b.animated = false;

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

        //for (uint i=0; i<mouthBones.length; ++i)
        //    Print(mouthBones[i]);

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

        AnimationController@ ac = face_node.GetComponent("AnimationController");
        ac.PlayExclusive("Animations/rabbit_ear_motion_Take 001.ani", 0, true, 0.1);
        ac.SetSpeed("Animations/rabbit_ear_motion_Take 001.ani", 0.25);

        for (uint i=0;i<facial_animations.length; ++i)
        {
            ac.Play(facial_animations[i], 1, true, 0);
            ac.SetWeight(facial_animations[i], facial_attributes[i]);
        }
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
            ac.Play(facial_animations[i], 1, true, 0);
            ac.SetWeight(facial_animations[i], facial_attributes[i]);
        }

        const float z_offset = -15.0F;
        Quaternion q(-yaw, roll, pitch + z_offset);
        rotate_bone_node.rotation = q;
    }

    void CreateRagdollBone(const String&in boneName, ShapeType type, const Vector3&in size, const Vector3&in position, const Quaternion&in rotation)
    {
        Node@ boneNode = face_node.GetChild(boneName, true);
        if (boneNode is null)
        {
            log.Warning("Could not find bone " + boneName + " for creating ragdoll physics components");
            return;
        }

        RigidBody@ body = boneNode.CreateComponent("RigidBody");
        // Set mass to make movable
        body.mass = 1.0f;
        // Set damping parameters to smooth out the motion
        body.linearDamping = 0.05f;
        body.angularDamping = 0.85f;
        // Set rest thresholds to ensure the ragdoll rigid bodies come to rest to not consume CPU endlessly
        body.linearRestThreshold = 1.5f;
        body.angularRestThreshold = 2.5f;

        CollisionShape@ shape = boneNode.CreateComponent("CollisionShape");
        // We use either a box or a capsule shape for all of the bones
        if (type == SHAPE_BOX)
            shape.SetBox(size, position, rotation);
        else
            shape.SetCapsule(size.x, size.y, position, rotation);
    }

    void CreateRagdollConstraint(const String&in boneName, const String&in parentName, ConstraintType type,
        const Vector3&in axis, const Vector3&in parentAxis, const Vector2&in highLimit, const Vector2&in lowLimit,
        bool disableCollision = true)
    {
        Node@ boneNode = face_node.GetChild(boneName, true);
        Node@ parentNode = face_node.GetChild(parentName, true);
        if (boneNode is null)
        {
            log.Warning("Could not find bone " + boneName + " for creating ragdoll constraint");
            return;
        }
        if (parentNode is null)
        {
            log.Warning("Could not find bone " + parentName + " for creating ragdoll constraint");
            return;
        }

        Constraint@ constraint = boneNode.CreateComponent("Constraint");
        constraint.constraintType = type;
        // Most of the constraints in the ragdoll will work better when the connected bodies don't collide against each other
        constraint.disableCollision = disableCollision;
        // The connected body must be specified before setting the world position
        constraint.otherBody = parentNode.GetComponent("RigidBody");
        // Position the constraint at the child bone we are connecting
        constraint.worldPosition = boneNode.worldPosition;
        // Configure axes and limits
        constraint.axis = axis;
        constraint.otherAxis = parentAxis;
        constraint.highLimit = highLimit;
        constraint.lowLimit = lowLimit;
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


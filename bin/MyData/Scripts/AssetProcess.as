// ==================================================================
//
//    Asset Process before game loading
//
// ==================================================================

enum RootMotionFlag
{
    kMotion_None= 0,
    kMotion_X   = (1 << 0),
    kMotion_Y   = (1 << 1),
    kMotion_Z   = (1 << 2),
    kMotion_R   = (1 << 3),

    kMotion_Ext_Rotate_From_Start = (1 << 4),
    kMotion_Ext_Debug_Dump = (1 << 5),
    kMotion_Ext_Adjust_Y = (1 << 6),
    kMotion_Ext_Foot_Based_Height = (1 << 7),

    kMotion_Ext_Translate_Ignore_Delta_Rotation = (1 << 8),
    kMotion_Ext_DoNotRotateAnimation = (1 << 9),

    kMotion_XZR = kMotion_X | kMotion_Z | kMotion_R,
    kMotion_YZR = kMotion_Y | kMotion_Z | kMotion_R,
    kMotion_XYR = kMotion_X | kMotion_Y | kMotion_R,

    kMotion_XZ  = kMotion_X | kMotion_Z,
    kMotion_XR  = kMotion_X | kMotion_R,
    kMotion_ZR  = kMotion_Z | kMotion_R,
    kMotion_XY  = kMotion_X | kMotion_Y,
    kMotion_YZ  = kMotion_Y | kMotion_Z,
    kMotion_XYZ = kMotion_XZ | kMotion_Y,
    kMotion_ALL = kMotion_XZR | kMotion_Y,
};

bool d_log = false;

const String TITLE = "AssetProcess";
const String TranslateBoneName = "Bip01_$AssimpFbx$_Translation";
const String RotateBoneName = "Bip01_$AssimpFbx$_Rotation";
const String ScaleBoneName = "Bip01_$AssimpFbx$_Scaling";

const String HEAD = "Bip01_Head";
const String L_HAND = "Bip01_L_Hand";
const String R_HAND = "Bip01_R_Hand";
const String L_FOOT = "Bip01_L_Foot";
const String R_FOOT = "Bip01_R_Foot";
const String L_ARM = "Bip01_L_Forearm";
const String R_ARM = "Bip01_R_Forearm";
const String L_CALF = "Bip01_L_Calf";
const String R_CALF = "Bip01_R_Calf";
const String PELVIS = "Bip01_Pelvis";

const float FRAME_PER_SEC = 30.0f;
const float SEC_PER_FRAME = 1.0f/FRAME_PER_SEC;
const float BIG_HEAD_SCALE = 2.0f;
const float ROTATION_FIX_DEGREE = 15.0f;
const float BONE_SCALE = 0.0254f;

Scene@  processScene;

class MotionRig
{
    Node@   processNode;
    Node@   translateNode;
    Node@   rotateNode;
    Skeleton@ skeleton;
    Vector3 pelvisRightAxis = Vector3(1, 0, 0);
    Quaternion rotateBoneInitQ;
    Vector3 pelvisOrign;
    String  rig;
    float left_foot_to_ground_height = 0.0f;
    float right_foot_to_ground_height = 0.0f;

    Node@   alignNode;

    MotionRig(const String& rigName)
    {
        rig = rigName;
        Model@ m = cache.GetResource("Model",  rigName);
        if (big_head_mode)
        {
            Vector3 v(BIG_HEAD_SCALE, BIG_HEAD_SCALE, BIG_HEAD_SCALE);
            Skeleton@ s = m.skeleton;
            s.GetBone(HEAD).initialScale = v;
            s.GetBone(L_HAND).initialScale = v;
            s.GetBone(R_HAND).initialScale = v;
            s.GetBone(L_FOOT).initialScale = v;
            s.GetBone(R_FOOT).initialScale = v;
        }

        Bone@ scaleBone = m.skeleton.GetBone(ScaleBoneName);
        Vector3 originScale = scaleBone.initialScale;
        if (scaleBone.initialScale.x > 1.0f)
            scaleBone.initialScale = Vector3(BONE_SCALE, BONE_SCALE, BONE_SCALE);

        processNode = processScene.CreateChild(rig + "_Character");
        Node@ renderNode = processNode.CreateChild("RenderNode");
        renderNode.rotation = Quaternion(0, -180, 0);

        AnimatedModel@ am = renderNode.CreateComponent("AnimatedModel");
        am.model = cache.GetResource("Model", rigName);

        skeleton = am.skeleton;
        Bone@ bone = skeleton.GetBone(RotateBoneName);
        rotateBoneInitQ = bone.initialRotation;

        pelvisRightAxis = rotateBoneInitQ * Vector3(1, 0, 0);
        pelvisRightAxis.Normalize();

        translateNode = renderNode.GetChild(TranslateBoneName, true);
        rotateNode = renderNode.GetChild(RotateBoneName, true);
        pelvisOrign = skeleton.GetBone(TranslateBoneName).initialPosition;

        left_foot_to_ground_height = renderNode.GetChild(L_FOOT, true).worldPosition.y;
        right_foot_to_ground_height = renderNode.GetChild(R_FOOT, true).worldPosition.y;

        alignNode = processScene.CreateChild(rig + "_Align");
        renderNode = alignNode.CreateChild("RenderNode");
        renderNode.rotation = Quaternion(0, -180, 0);

        AnimatedModel@ am2 = renderNode.CreateComponent("AnimatedModel");
        am2.model = am.model;

        LogPrint(rigName +
            " pelvisRightAxis=" + pelvisRightAxis.ToString() +
            " pelvisOrign=" + pelvisOrign.ToString() +
            " numBones=" + skeleton.numBones +
            " initialScale=" + originScale.ToString() +
            " left_foot_to_ground_height=" + left_foot_to_ground_height +
            " right_foot_to_ground_height=" + right_foot_to_ground_height);
    }

    ~MotionRig()
    {
        processNode.Remove();
        alignNode.Remove();
    }
};

MotionRig@ curRig;

Vector3 GetProjectedAxis(MotionRig@ rig, Node@ node, const Vector3&in axis)
{
    Vector3 p = node.worldRotation * axis;
    p.Normalize();
    Vector3 ret = rig.processNode.worldRotation.Inverse() * p;
    ret.Normalize();
    ret.y = 0;
    return ret;
}

Quaternion GetRotationInXZPlane(MotionRig@ rig, const Quaternion&in startLocalRot, const Quaternion&in curLocalRot)
{
    Node@ rotateNode = rig.rotateNode;
    rotateNode.rotation = startLocalRot;
    Vector3 startAxis = GetProjectedAxis(rig, rotateNode, rig.pelvisRightAxis);
    rotateNode.rotation = curLocalRot;
    Vector3 curAxis = GetProjectedAxis(rig, rotateNode, rig.pelvisRightAxis);
    return Quaternion(startAxis, curAxis);
}

void DumpSkeletonNames(Node@ n)
{
    AnimatedModel@ model = n.GetComponent("AnimatedModel");
    if (model is null)
        model = n.children[0].GetComponent("AnimatedModel");
    if (model is null)
        return;

    Skeleton@ skeleton = model.skeleton;
    for (uint i=0; i<skeleton.numBones; ++i)
    {
        LogPrint(skeleton.bones[i].name);
    }
}

void AssetPreProcess()
{
    processScene = Scene();
}

void AssignMotionRig(const String& rigName)
{
    @curRig = MotionRig(rigName);
}

void RotateAnimation(MotionRig@ rig, const String&in animationFile, float rotateAngle)
{
    if (d_log)
        LogPrint("Rotating animation " + animationFile);

    Animation@ anim = cache.GetResource("Animation", animationFile);
    if (anim is null) {
        ErrorDialog(TITLE, animationFile + " not found!");
        engine.Exit();
        return;
    }

    AnimationTrack@ translateTrack = anim.tracks[TranslateBoneName];
    AnimationTrack@ rotateTrack = anim.tracks[RotateBoneName];
    Quaternion q(0, rotateAngle, 0);
    Node@ rotateNode = rig.rotateNode;

    if (rotateTrack !is null)
    {
        for (uint i=0; i<rotateTrack.numKeyFrames; ++i)
        {
            AnimationKeyFrame kf(rotateTrack.keyFrames[i]);
            rotateNode.rotation = kf.rotation;
            Quaternion wq = rotateNode.worldRotation;
            wq = q * wq;
            rotateNode.worldRotation = wq;
            kf.rotation = rotateNode.rotation;
            rotateTrack.keyFrames[i] = kf;
        }
    }
    if (translateTrack !is null)
    {
        for (uint i=0; i<translateTrack.numKeyFrames; ++i)
        {
            AnimationKeyFrame kf(translateTrack.keyFrames[i]);
            kf.position = q * kf.position;
            translateTrack.keyFrames[i] = kf;
        }
    }
}

void TranslateAnimation(const String&in animationFile, const Vector3&in diff)
{
    if (d_log)
        LogPrint("Translating animation " + animationFile);

    Animation@ anim = cache.GetResource("Animation", animationFile);
    if (anim is null) {
        ErrorDialog(TITLE, animationFile + " not found!");
        engine.Exit();
        return;
    }

    AnimationTrack@ translateTrack = anim.tracks[TranslateBoneName];
    if (translateTrack !is null)
    {
        for (uint i=0; i<translateTrack.numKeyFrames; ++i)
        {
            AnimationKeyFrame kf(translateTrack.keyFrames[i]);
            kf.position += diff;
            translateTrack.keyFrames[i] = kf;
        }
    }
}

void CollectBoneWorldPositions(MotionRig@ rig, const String&in animationFile, const String& boneName, Array<Vector3>@ outPositions)
{
    Animation@ anim = cache.GetResource("Animation", animationFile);
    if (anim is null) {
        ErrorDialog(TITLE, animationFile + " not found!");
        engine.Exit();
        return;
    }

    AnimationTrack@ track = anim.tracks[boneName];
    if (track is null)
        return;

    AnimatedModel@ am = rig.alignNode.children[0].GetComponent("AnimatedModel");
    am.RemoveAllAnimationStates();
    AnimationState@ state = am.AddAnimationState(anim);
    state.weight = 1.0f;
    state.looped = false;

    outPositions.Resize(track.numKeyFrames);
    Node@ boneNode = rig.alignNode.GetChild(boneName, true);

    for (uint i=0; i<track.numKeyFrames; ++i)
    {
        state.time = track.keyFrames[i].time;
        state.Apply();
        rig.alignNode.MarkDirty();
        outPositions[i] = boneNode.worldPosition;
        // LogPrint("out-position=" + outPositions[i].ToString());
    }
}

Vector3 GetBoneWorldPosition(MotionRig@ rig, const String&in animationFile, const String& boneName, float t)
{
    Animation@ anim = cache.GetResource("Animation", animationFile);
    if (anim is null) {
        ErrorDialog(TITLE, animationFile + " not found!");
        engine.Exit();
        return Vector3();
    }

    rig.alignNode.worldPosition = Vector3();
    rig.alignNode.worldRotation = Quaternion();
    AnimatedModel@ am = rig.alignNode.children[0].GetComponent("AnimatedModel");
    am.RemoveAllAnimationStates();
    AnimationState@ state = am.AddAnimationState(anim);
    state.weight = 1.0f;
    state.looped = false;
    state.time = t;
    state.Apply();
    rig.alignNode.MarkDirty();
    return  rig.alignNode.GetChild(boneName, true).worldPosition;
}

void FixAnimationOrigin(MotionRig@ rig, const String&in animationFile, int motionFlag)
{
    Animation@ anim = cache.GetResource("Animation", animationFile);
    if (anim is null) {
        ErrorDialog(TITLE, animationFile + " not found!");
        engine.Exit();
        return;
    }

    AnimationTrack@ translateTrack = anim.tracks[TranslateBoneName];
    if (translateTrack is null)
    {
        LogPrint(animationFile + " translation track not found!!!");
        return;
    }

    Node@ translateNode = rig.translateNode;

    int translateFlag = 0;
    Vector3 position = translateTrack.keyFrames[0].position - rig.pelvisOrign;
    const float minDist = 0.5f;
    if (Abs(position.x) > minDist) {
        if (d_log)
            LogPrint(animationFile + " Need reset x position");
        translateFlag |= kMotion_X;
    }
    if (Abs(position.y) > 2.0f && (motionFlag & kMotion_Ext_Adjust_Y != 0)) {
        if (d_log)
            LogPrint(animationFile + " Need reset y position");
        translateFlag |= kMotion_Y;
    }
    if (Abs(position.z) > minDist) {
        if (d_log)
            LogPrint(animationFile + " Need reset z position");
        translateFlag |= kMotion_Z;
    }
    if (d_log)
        LogPrint("t-diff-position=" + position.ToString());

    if (translateFlag == 0)
        return;

    Vector3 firstKeyPos = translateTrack.keyFrames[0].position;
    translateNode.position = firstKeyPos;
    Vector3 currentWS = translateNode.worldPosition;
    Vector3 oldWS = currentWS;

    if (translateFlag & kMotion_X != 0)
        currentWS.x = rig.pelvisOrign.x;
    if (translateFlag & kMotion_Y != 0)
        currentWS.y = rig.pelvisOrign.y;
    if (translateFlag & kMotion_Z != 0)
        currentWS.z = rig.pelvisOrign.z;

    translateNode.worldPosition = currentWS;
    Vector3 currentLS = translateNode.position;
    Vector3 originDiffLS = currentLS - firstKeyPos;
    TranslateAnimation(animationFile, originDiffLS);
}

void ProcessAnimation(MotionRig@ rig, const String&in animationFile, int motionFlag, int allowMotion, Array<Vector4>&out outKeys, Vector4&out startFromOrigin)
{
    bool dump = motionFlag & kMotion_Ext_Debug_Dump != 0;
    if (d_log)
        dump = true;

    if (dump)
    {
        LogPrint("---------------------------------------------------------------------------------------");
        LogPrint("Processing animation " + animationFile);
    }

    Animation@ anim = cache.GetResource("Animation", animationFile);
    if (anim is null) {
        ErrorDialog(TITLE, animationFile + " not found!");
        engine.Exit();
        return;
    }

    FixAnimation(anim);

    AnimationTrack@ translateTrack = anim.tracks[TranslateBoneName];
    if (translateTrack is null)
    {
        LogPrint(animationFile + " translation track not found!!!");
        return;
    }

    AnimationTrack@ rotateTrack = anim.tracks[RotateBoneName];
    Node@ rotateNode = rig.rotateNode;
    Node@ translateNode = rig.translateNode;

    bool cutRotation = motionFlag & kMotion_Ext_Rotate_From_Start != 0;
    float firstRotateFromRoot = 0;
    bool rotate = false;
    bool footBased = motionFlag & kMotion_Ext_Foot_Based_Height != 0;
    int translateFlag = 0;
    bool rotateMotion = motionFlag & kMotion_R != 0;

    // ==============================================================
    // pre process key frames
    if (rotateTrack !is null && rotateMotion)
    {
        firstRotateFromRoot = GetRotationInXZPlane(rig, rig.rotateBoneInitQ, rotateTrack.keyFrames[0].rotation).eulerAngles.y;
        if (Abs(firstRotateFromRoot) >= ROTATION_FIX_DEGREE)
        {
            if (dump)
                LogPrint(animationFile + " Need to rotate whole animation since the first rotation key is not zero, rotation=" + firstRotateFromRoot);
            rotate = true;
        }
        startFromOrigin.w = firstRotateFromRoot;
    }

    if (motionFlag & kMotion_Ext_DoNotRotateAnimation != 0)
        rotate = false;

    // get start offset
    translateNode.position = translateTrack.keyFrames[0].position;
    Vector3 t_ws1 = translateNode.worldPosition;
    translateNode.position = rig.pelvisOrign;
    Vector3 t_ws2 = translateNode.worldPosition;
    Vector3 diff = t_ws1 - t_ws2;
    startFromOrigin.x = diff.x;
    startFromOrigin.y = diff.y;
    startFromOrigin.z = diff.z;

    if (rotate)
        RotateAnimation(rig, animationFile, -firstRotateFromRoot);
    FixAnimationOrigin(rig, animationFile, motionFlag);

    /*if (rotateTrack !is null)
    {
        for (uint i=0; i<rotateTrack.numKeyFrames; ++i)
        {
            Quaternion q = GetRotationInXZPlane(rig, rig.rotateBoneInitQ, rotateTrack.keyFrames[i].rotation);
            if (d_log)
            {
                if (i == 0 || i == rotateTrack.numKeyFrames - 1)
                    LogPrint("frame=" + String(i) + " rotation from identical in xz plane=" + q.eulerAngles.ToString());
            }
            if (i == 0)
                firstRotateFromRoot = q.eulerAngles.y;
        }
    }*/

    outKeys.Resize(translateTrack.numKeyFrames);

    // process rotate key frames first
    if (rotateMotion && rotateTrack !is null)
    {
        Quaternion lastRot = rotateTrack.keyFrames[0].rotation;
        float rotateFromStart = cutRotation ? firstRotateFromRoot : 0;
        for (uint i=0; i<rotateTrack.numKeyFrames; ++i)
        {
            AnimationKeyFrame kf(rotateTrack.keyFrames[i]);
            Quaternion q = GetRotationInXZPlane(rig, lastRot, kf.rotation);
            lastRot = kf.rotation;
            outKeys[i].w = rotateFromStart;
            // outKeys[i].w = AngleDiff(outKeys[i].w);
            /*if (outKeys[i].w > 360)
                outKeys[i].w -= 360;
            if (outKeys[i].w < -360)
                outKeys[i].w += 360;*/
            rotateFromStart += q.eulerAngles.y;

            if (dump)
                LogPrint("rotation from last frame = " + String(q.eulerAngles.y) + " rotateFromStart=" + String(rotateFromStart));

            q = Quaternion(0, rotateFromStart, 0).Inverse();

            Quaternion wq = rotateNode.worldRotation;
            wq = q * wq;
            rotateNode.worldRotation = wq;
            kf.rotation = rotateNode.rotation;

            rotateTrack.keyFrames[i] = kf;
        }
    }

    if ((motionFlag & kMotion_X) != 0 ||
        (motionFlag & kMotion_Y) != 0 ||
        (motionFlag & kMotion_Z) != 0)
    {
        Vector3 firstKeyPos = Vector3::ZERO; // translateTrack.keyFrames[0].position;
        for (uint i=0; i<translateTrack.numKeyFrames; ++i)
        {
            AnimationKeyFrame kf(translateTrack.keyFrames[i]);
            translateNode.position = firstKeyPos;
            Vector3 t1_ws = translateNode.worldPosition;
            translateNode.position = kf.position;
            Vector3 t2_ws = translateNode.worldPosition;
            Vector3 translation = t2_ws - t1_ws;
            if (motionFlag & kMotion_X != 0)
            {
                outKeys[i].x = translation.x;
                t2_ws.x  = t1_ws.x;
            }
            if (motionFlag & kMotion_Y != 0 && !footBased)
            {
                outKeys[i].y = translation.y;
                t2_ws.y = t1_ws.y;
            }
            if (motionFlag & kMotion_Z != 0)
            {
                outKeys[i].z = translation.z;
                t2_ws.z = t1_ws.z;
            }

            translateNode.worldPosition = t2_ws;
            Vector3 local_pos = translateNode.position;
            // LogPrint("local position from " + kf.position.ToString() + " to " + local_pos.ToString());
            kf.position = local_pos;
            translateTrack.keyFrames[i] = kf;
        }
    }

    if (footBased)
    {
        Array<Vector3> leftFootPositions;
        Array<Vector3> rightFootPositions;
        CollectBoneWorldPositions(rig, animationFile, L_FOOT, leftFootPositions);
        CollectBoneWorldPositions(rig, animationFile, R_FOOT, rightFootPositions);
        Array<float> ground_heights;
        ground_heights.Resize(leftFootPositions.length);
        for (uint i=0; i<translateTrack.numKeyFrames; ++i)
        {
            AnimationKeyFrame kf(translateTrack.keyFrames[i]);
            float ground_y = 0;
            if (rightFootPositions[i].y < leftFootPositions[i].y)
                ground_y = rightFootPositions[i].y - rig.right_foot_to_ground_height;
            else
                ground_y = leftFootPositions[i].y - rig.left_foot_to_ground_height;
            kf.position.y -= ground_y;
            translateTrack.keyFrames[i] = kf;
            ground_heights[i] = ground_y;
        }

        if (motionFlag & kMotion_Y != 0)
        {
            for (uint i=0; i<ground_heights.length; ++i)
                outKeys[i].y = ground_heights[i] - ground_heights[0];
        }
    }

    for (uint i=0; i<outKeys.length; ++i)
    {
        Vector3 v_motion(outKeys[i].x, outKeys[i].y, outKeys[i].z);
        outKeys[i].x = v_motion.x;
        outKeys[i].y = v_motion.y;
        outKeys[i].z = v_motion.z;

        if (allowMotion & kMotion_X == 0)
            outKeys[i].x = 0;
        if (allowMotion & kMotion_Y == 0)
            outKeys[i].y = 0;
        if (allowMotion & kMotion_Z == 0)
            outKeys[i].z = 0;
        if (allowMotion & kMotion_R == 0)
            outKeys[i].w = 0;
    }

    if (dump)
    {
        for (uint i=0; i<outKeys.length; ++i)
        {
            LogPrint("Frame " + String(i) + " motion-key=" + outKeys[i].ToString());
        }
        LogPrint("---------------------------------------------------------------------------------------");
    }
}

void FixAnimation(const String&in animationFile)
{
    if (d_log)
        LogPrint("Fix animation " + animationFile);

    Animation@ anim = cache.GetResource("Animation", animationFile);
    if (anim is null) {
        ErrorDialog(TITLE, animationFile + " not found!");
        engine.Exit();
        return;
    }

   FixAnimation(anim);
}

void FixAnimation(Animation@ anim)
{
    if (anim is null)
        return;
    // return;

    // Print("Fixing animation for " + anim.name);
    bool fixed = false;
    AnimationTrack@ scaleTrack = anim.tracks[ScaleBoneName];
    if (scaleTrack is null)
    {
        Print("no scale track + " + ScaleBoneName);
        AnimationTrack@ track = anim.CreateTrack(ScaleBoneName);
        AnimationTrack@ t = anim.tracks[TranslateBoneName];
        for (uint i=0; i<t.numKeyFrames; ++i)
        {
            AnimationKeyFrame kf;
            track.channelMask = CHANNEL_SCALE;
            kf.time = t.keyFrames[i].time;
            kf.scale = Vector3(BONE_SCALE, BONE_SCALE, BONE_SCALE);
            track.AddKeyFrame(kf);
        }

        fixed = true;
    }
    else
    {
        /*Print(anim.name + " has scale track.");
        for (uint i=0; i<scaleTrack.numKeyFrames; ++i)
        {
            AnimationKeyFrame kf(scaleTrack.keyFrames[i]);
            if (kf.scale.x > 2.0f)
            {
                kf.scale = Vector3(BONE_SCALE, BONE_SCALE, BONE_SCALE);
                fixed = true;
            }
            scaleTrack.keyFrames[i] = kf;
        }*/
    }

    if (fixed)
        LogPrint("Fixed animation --> scale bone" + anim.name);
}

void AssetPostProcess()
{
    @curRig = null;
    if (processScene !is null)
        processScene.Remove();
    @processScene = null;
}

Animation@ FindAnimation(const String&in name)
{
   return cache.GetResource("Animation", GetAnimationName(name));
}

String GetAnimationName(const String&in name)
{
    return "Animations/" + name + "_Take 001.ani";
}

String FileNameToMotionName(const String&in name)
{
    return name.Substring(0, name.length - 13);
}

// clamps an angle to the rangle of [-PI, PI]
float AngleDiff( float diff )
{
    if (diff > 180)
        diff -= 360;
    if (diff < -180)
        diff += 360;
    return diff;
}

void Animation_AddTrigger(const String&in name, int frame, const VariantMap&in data)
{
    Animation@ anim = cache.GetResource("Animation", GetAnimationName(name));
    if (anim !is null)
        anim.AddTrigger(float(frame) * SEC_PER_FRAME, false, Variant(data));
}

void AddAnimationTrigger(const String&in name, int frame, const String&in tag)
{
    AddAnimationTrigger(name, frame, StringHash(tag));
}

void AddAnimationTrigger(const String&in name, int frame, const StringHash&in tag)
{
    VariantMap eventData;
    eventData[NAME] = tag;
    Animation_AddTrigger(name, frame, eventData);
}

void AddFloatAnimationTrigger(const String&in name, int frame, const StringHash&in tag, float value)
{
    VariantMap eventData;
    eventData[NAME] = tag;
    eventData[VALUE] = value;
    Animation_AddTrigger(name, frame, eventData);
}

void AddIntAnimationTrigger(const String&in name, int frame, const StringHash&in tag, int value)
{
    VariantMap eventData;
    eventData[NAME] = tag;
    eventData[VALUE] = value;
    Animation_AddTrigger(name, frame, eventData);
}

void AddStringAnimationTrigger(const String&in name, int frame, const StringHash&in tag, const String&in value)
{
    VariantMap eventData;
    eventData[NAME] = tag;
    eventData[VALUE] = value;
    Animation_AddTrigger(name, frame, eventData);
}

void AddStringHashAnimationTrigger(const String&in name, int frame, const StringHash&in tag, const StringHash&in value)
{
    VariantMap eventData;
    eventData[NAME] = tag;
    eventData[VALUE] = value;
    Animation_AddTrigger(name, frame, eventData);
}

void AddAttackTrigger(const String&in name, int startFrame, int endFrame, const String&in boneName)
{
    VariantMap eventData;
    eventData[NAME] = ATTACK_CHECK;
    eventData[VALUE] = 1;
    eventData[BONE] = boneName;
    Animation_AddTrigger(name, startFrame, eventData);
    eventData[VALUE] = 0;
    Animation_AddTrigger(name, endFrame + 1, eventData);
}

void AddRagdollTrigger(const String&in name, int prepareFrame, int startFrame)
{
    if (prepareFrame >= 0)
        AddAnimationTrigger(name, prepareFrame, RAGDOLL_PERPARE);
    AddAnimationTrigger(name, startFrame, RAGDOLL_START);
}

void AddComplexAttackTrigger(const String&in name, int counterStart, int counterEnd, int attackStart, int attackEnd, const String&in attackBone)
{
    AddFloatAnimationTrigger(name, counterStart, TIME_SCALE, 0.3f);
    AddFloatAnimationTrigger(name, counterEnd, TIME_SCALE, 1.0f);
    AddIntAnimationTrigger(name, counterStart, COUNTER_CHECK, 1);
    AddIntAnimationTrigger(name, counterEnd, COUNTER_CHECK, 0);
    AddAttackTrigger(name, attackStart, attackEnd, attackBone);
}
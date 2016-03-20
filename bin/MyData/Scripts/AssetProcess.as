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

    kMotion_XZR = kMotion_X | kMotion_Z | kMotion_R,
    kMotion_XZ  = kMotion_X | kMotion_Z,
    kMotion_XR  = kMotion_X | kMotion_R,
    kMotion_ZR  = kMotion_Z | kMotion_R,
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

const float FRAME_PER_SEC = 30.0f;
const float SEC_PER_FRAME = 1.0f/FRAME_PER_SEC;
const int   PROCESS_TIME_PER_FRAME = 60; // ms
const float BONE_SCALE = 100.0f;
const float BIG_HEAD_SCALE = 2.0f;

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

    MotionRig(const String& rigName)
    {
        if (bigHeadMode)
        {
            Vector3 v(BIG_HEAD_SCALE, BIG_HEAD_SCALE, BIG_HEAD_SCALE);
            Model@ m = cache.GetResource("Model",  rigName);
            Skeleton@ s = m.skeleton;
            s.GetBone(HEAD).initialScale = v;
            s.GetBone(L_HAND).initialScale = v;
            s.GetBone(R_HAND).initialScale = v;
            s.GetBone(L_FOOT).initialScale = v;
            s.GetBone(R_FOOT).initialScale = v;
        }

        processNode = processScene.CreateChild("Character");
        processNode.worldRotation = Quaternion(0, 180, 0);

        AnimatedModel@ am = processNode.CreateComponent("AnimatedModel");
        am.model = cache.GetResource("Model", rigName);

        skeleton = am.skeleton;
        Bone@ bone = skeleton.GetBone(RotateBoneName);
        rotateBoneInitQ = bone.initialRotation;

        pelvisRightAxis = rotateBoneInitQ * Vector3(1, 0, 0);
        pelvisRightAxis.Normalize();

        translateNode = processNode.GetChild(TranslateBoneName, true);
        rotateNode = processNode.GetChild(RotateBoneName, true);
        pelvisOrign = skeleton.GetBone(TranslateBoneName).initialPosition;

        Print(rigName + " pelvisRightAxis = " + pelvisRightAxis.ToString() + " pelvisOrign=" + pelvisOrign.ToString());
    }

    ~MotionRig()
    {
        processNode.Remove();
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
        Print(skeleton.bones[i].name);
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

void RotateAnimation(const String&in animationFile, float rotateAngle)
{
    if (d_log)
        Print("Rotating animation " + animationFile);

    Animation@ anim = cache.GetResource("Animation", animationFile);
    if (anim is null) {
        ErrorDialog(TITLE, animationFile + " not found!");
        engine.Exit();
        return;
    }

    AnimationTrack@ translateTrack = anim.tracks[TranslateBoneName];
    AnimationTrack@ rotateTrack = anim.tracks[RotateBoneName];
    Quaternion q(0, rotateAngle, 0);
    Node@ rotateNode = curRig.rotateNode;

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
        Print("Translating animation " + animationFile);

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

float ProcessAnimation(const String&in animationFile, int motionFlag, int allowMotion, float rotateAngle, Array<Vector4>&out outKeys, Vector4&out startFromOrigin)
{
    if (d_log)
    {
        Print("---------------------------------------------------------------------------------------");
        Print("Processing animation " + animationFile);
    }

    Animation@ anim = cache.GetResource("Animation", animationFile);
    if (anim is null) {
        ErrorDialog(TITLE, animationFile + " not found!");
        engine.Exit();
        return 0;
    }

    AnimationTrack@ translateTrack = anim.tracks[TranslateBoneName];
    if (translateTrack is null)
    {
        Print(animationFile + " translation track not found!!!");
        return 0;
    }

    AnimationTrack@ rotateTrack = anim.tracks[RotateBoneName];
    Quaternion flipZ_Rot(0, 180, 0);
    Node@ rotateNode = curRig.rotateNode;
    Node@ translateNode = curRig.translateNode;
    MotionRig@ rig = curRig;

    bool cutRotation = motionFlag & kMotion_Ext_Rotate_From_Start != 0;
    bool dump = motionFlag & kMotion_Ext_Debug_Dump != 0;
    float firstRotateFromRoot = 0;
    bool flip = false;
    int translateFlag = 0;

    // ==============================================================
    // pre process key frames
    if (rotateTrack !is null && rotateAngle > 360)
    {
        firstRotateFromRoot = GetRotationInXZPlane(rig, rig.rotateBoneInitQ, rotateTrack.keyFrames[0].rotation).eulerAngles.y;
        if (Abs(firstRotateFromRoot) > 75)
        {
            if (d_log)
                Print(animationFile + " Need to flip rotate track since object is start opposite, rotation=" + firstRotateFromRoot);
            flip = true;
        }
        startFromOrigin.w = firstRotateFromRoot;
    }

    if (translateTrack !is null)
    {
        translateNode.position = translateTrack.keyFrames[0].position;
        Vector3 t_ws1 = translateNode.worldPosition;
        translateNode.position = rig.pelvisOrign;
        Vector3 t_ws2 = translateNode.worldPosition;
        Vector3 diff = t_ws1 - t_ws2;
        startFromOrigin.x = diff.x;
        startFromOrigin.y = diff.y;
        startFromOrigin.z = diff.z;
    }

    if (rotateAngle < 360)
        RotateAnimation(animationFile, rotateAngle);
    else if (flip)
        RotateAnimation(animationFile, 180);

    if (translateTrack !is null)
    {
        Vector3 position = translateTrack.keyFrames[0].position - rig.pelvisOrign;
        const float minDist = 0.5f;
        if (Abs(position.x) > minDist) {
            if (d_log)
                Print(animationFile + " Need reset x position");
            translateFlag |= kMotion_X;
        }
        if (Abs(position.y) > 2.0f && (motionFlag & kMotion_Y != 0)) {
            if (d_log)
                Print(animationFile + " Need reset y position");
            translateFlag |= kMotion_Y;
        }
        if (Abs(position.z) > minDist) {
            if (d_log)
                Print(animationFile + " Need reset z position");
            translateFlag |= kMotion_Z;
        }
        if (d_log)
            Print("t-diff-position=" + position.ToString());
    }

    if (translateFlag != 0 && translateTrack !is null)
    {
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

    if (rotateTrack !is null)
    {
        for (uint i=0; i<rotateTrack.numKeyFrames; ++i)
        {
            Quaternion q = GetRotationInXZPlane(rig, rig.rotateBoneInitQ, rotateTrack.keyFrames[i].rotation);
            if (d_log)
            {
                if (i == 0 || i == rotateTrack.numKeyFrames - 1)
                    Print("frame=" + String(i) + " rotation from identical in xz plane=" + q.eulerAngles.ToString());
            }
            if (i == 0)
                firstRotateFromRoot = q.eulerAngles.y;
        }
    }

    outKeys.Resize(translateTrack.numKeyFrames);

    // process rotate key frames first
    if ((motionFlag & kMotion_R != 0) && rotateTrack !is null)
    {
        Quaternion lastRot = rotateTrack.keyFrames[0].rotation;
        float rotateFromStart = cutRotation ? firstRotateFromRoot : 0;
        for (uint i=0; i<rotateTrack.numKeyFrames; ++i)
        {
            AnimationKeyFrame kf(rotateTrack.keyFrames[i]);
            Quaternion q = GetRotationInXZPlane(rig, lastRot, kf.rotation);
            lastRot = kf.rotation;
            outKeys[i].w = rotateFromStart;
            rotateFromStart += q.eulerAngles.y;

            if (dump)
                Print("rotation from last frame = " + String(q.eulerAngles.y) + " rotateFromStart=" + String(rotateFromStart));

            q = Quaternion(0, rotateFromStart, 0).Inverse();

            Quaternion wq = rotateNode.worldRotation;
            wq = q * wq;
            rotateNode.worldRotation = wq;
            kf.rotation = rotateNode.rotation;

            rotateTrack.keyFrames[i] = kf;
        }
    }

    bool rotateMotion = motionFlag & kMotion_R != 0;
    motionFlag &= (~kMotion_R);
    if (motionFlag != 0 && translateTrack !is null)
    {
        Vector3 firstKeyPos = translateTrack.keyFrames[0].position;

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
            if (motionFlag & kMotion_Y != 0)
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
            // Print("local position from " + kf.position.ToString() + " to " + local_pos.ToString());
            kf.position = local_pos;
            translateTrack.keyFrames[i] = kf;
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
            Print("Frame " + String(i) + " motion-key=" + outKeys[i].ToString());
        }
    }

    if (d_log)
        Print("---------------------------------------------------------------------------------------");

    if (rotateAngle < 360)
        return rotateAngle;
    else
        return flip ? 180 : 0;
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

// clamps an angle to the rangle of [-2PI, 2PI]
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

void AddParticleTrigger(const String&in name, int startFrame, const String&in boneName, const String&in effectName, float duration)
{
    VariantMap eventData;
    eventData[NAME] = ATTACK_CHECK;
    eventData[VALUE] = effectName;
    eventData[BONE] = boneName;
    eventData[DURATION] = duration;
    Animation_AddTrigger(name, startFrame, eventData);
}

void AddComplexAttackTrigger(const String&in name, int counterStart, int counterEnd, int attackStart, int attackEnd, const String&in attackBone)
{
    AddFloatAnimationTrigger(name, counterStart, TIME_SCALE, 0.3f);
    AddFloatAnimationTrigger(name, counterEnd, TIME_SCALE, 1.0f);
    AddIntAnimationTrigger(name, counterStart, COUNTER_CHECK, 1);
    AddIntAnimationTrigger(name, counterEnd, COUNTER_CHECK, 0);
    AddAttackTrigger(name, attackStart, attackEnd, attackBone);
}
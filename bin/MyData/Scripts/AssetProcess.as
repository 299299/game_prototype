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
    kMotion_XZR = kMotion_X | kMotion_Z | kMotion_R,
    kMotion_XZ  = kMotion_X | kMotion_Z,
    kMotion_XR  = kMotion_X | kMotion_R,
    kMotion_ZR  = kMotion_Z | kMotion_R,
};

const String TITLE = "AssetProcess";
const String TranslateBoneName = "Bip01_$AssimpFbx$_Translation";
const String RotateBoneName = "Bip01_$AssimpFbx$_Rotation";
const String ScaleBoneName = "Bip01_$AssimpFbx$_Scaling";
const String rigName = "Models/bruce.mdl";

const String HEAD = "Bip01_Head";
const String L_HAND = "Bip01_L_Hand";
const String R_HAND = "Bip01_R_Hand";
const String L_FOOT = "Bip01_L_Foot";
const String R_FOOT = "Bip01_R_Foot";
const String L_ARM = "Bip01_L_Forearm";
const String R_ARM = "Bip01_R_Forearm";
const String L_CALF = "Bip01_L_Calf";
const String R_CALF = "Bip01_R_Calf";

Scene@  processScene;
Node@   processNode;
Node@   translateNode;
Node@   rotateNode;
Skeleton@ skeleton;

Vector3 pelvisRightAxis = Vector3(1, 0, 0);
Quaternion rotateBoneInitQ;

Vector3 pelvisOrign;

const float FRAME_PER_SEC = 30.0f;
const float SEC_PER_FRAME = 1.0f/FRAME_PER_SEC;
const int   PROCESS_TIME_PER_FRAME = 16; // ms

bool d_log = false;

Vector3 GetProjectedAxis(Node@ node, const Vector3&in axis)
{
    Vector3 p = node.worldRotation * axis;
    p.Normalize();
    Vector3 ret = processNode.worldRotation.Inverse() * p;
    ret.Normalize();
    ret.y = 0;
    return ret;
}

Quaternion GetRotationInXZPlane(Node@ rotateNode, const Quaternion&in startLocalRot, const Quaternion&in curLocalRot)
{
    rotateNode.rotation = startLocalRot;
    Vector3 startAxis = GetProjectedAxis(rotateNode, pelvisRightAxis);
    rotateNode.rotation = curLocalRot;
    Vector3 curAxis = GetProjectedAxis(rotateNode, pelvisRightAxis);
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
    if (bigHeadMode)
    {
        const float bigHeadScale = 2.0f;
        Vector3 v(bigHeadScale, bigHeadScale, bigHeadScale);

        Model@ m1 = cache.GetResource("Model",  "Models/bruce.mdl");
        Skeleton@ s1 = m1.skeleton;
        s1.GetBone(HEAD).initialScale = v;
        s1.GetBone(L_HAND).initialScale = v;
        s1.GetBone(R_HAND).initialScale = v;
        s1.GetBone(L_FOOT).initialScale = v;
        s1.GetBone(R_FOOT).initialScale = v;

        m1 = cache.GetResource("Model",  "Models/thug.mdl");
        s1 = m1.skeleton;
        s1.GetBone(HEAD).initialScale = v;
        s1.GetBone(L_HAND).initialScale = v;
        s1.GetBone(R_HAND).initialScale = v;
        s1.GetBone(L_FOOT).initialScale = v;
        s1.GetBone(R_FOOT).initialScale = v;
    }


    processScene = Scene();
    processNode = processScene.CreateChild("Character");
    processNode.worldRotation = Quaternion(0, 180, 0);

    AnimatedModel@ am = processNode.CreateComponent("AnimatedModel");
    am.model = cache.GetResource("Model", rigName);

    skeleton = am.skeleton;
    Bone@ bone = skeleton.GetBone(RotateBoneName);
    rotateBoneInitQ = bone.initialRotation;

    pelvisRightAxis = rotateBoneInitQ * Vector3(1, 0, 0);
    pelvisRightAxis.Normalize();
    Print("pelvisRightAxis = " + pelvisRightAxis.ToString());

    translateNode = processNode.GetChild(TranslateBoneName, true);
    rotateNode = processNode.GetChild(RotateBoneName, true);
    pelvisOrign = skeleton.GetBone(TranslateBoneName).initialPosition;
}

void ProcessAnimation(const String&in animationFile, int motionFlag, int originFlag, int allowMotion, bool cutRotation, Array<Vector4>&out outKeys, Vector3&out startFromOrigin, bool dump = false)
{
    if (d_log)
        Print("Processing animation " + animationFile);

    Animation@ anim = cache.GetResource("Animation", animationFile);
    if (anim is null) {
        ErrorDialog(TITLE, animationFile + " not found!");
        engine.Exit();
        return;
    }

    /*
    if (anim.tracks["Bip01_$AssimpFbx$_PreRotation"] !is null)
        Print("Bip01_$AssimpFbx$_PreRotation has track");
    if (anim.tracks["Bip01_$AssimpFbx$_Scaling"] !is null)
        Print("Bip01_$AssimpFbx$_Scaling");
    */

    AnimationTrack@ translateTrack = anim.tracks[TranslateBoneName];
    AnimationTrack@ rotateTrack = anim.tracks[RotateBoneName];
    Quaternion flipZ_Rot(0, 180, 0);

    //AnimationTrack@ track = anim.tracks["Bip01_L_Hand"];
    //if (track.channelMask & CHANNEL_SCALE != 0)
    //    Print("CHANNEL_SCALE");

    bool fixOriginFlag = originFlag <= 0;

    // ==============================================================
    // pre process key frames
    if (rotateTrack !is null && fixOriginFlag)
    {
        float rotation = GetRotationInXZPlane(rotateNode, rotateBoneInitQ, rotateTrack.keyFrames[0].rotation).eulerAngles.y;
        if (Abs(rotation) > 75)
        {
            if (d_log)
                Print("Need to flip rotate track since object is start opposite, rotation=" + rotation);
            originFlag |= kMotion_R;
        }
    }

    if (translateTrack !is null && fixOriginFlag)
    {
        Vector3 position = translateTrack.keyFrames[0].position - pelvisOrign;
        const float minDist = 0.5f;
        if (Abs(position.x) > minDist) {
            if (d_log)
                Print("Need reset x position");
            originFlag |= kMotion_X;
        }
        if (Abs(position.y) > 2.0f) {
            // Print("Need reset y position");
            // riginFlag |= kMotion_Y;
        }
        if (Abs(position.z) > minDist) {
            if (d_log)
                Print("Need reset z position");
            originFlag |= kMotion_Z;
        }
        if (d_log)
            Print("t-diff-position=" + position.ToString());
    }

    if (originFlag & kMotion_R != 0)
    {
        if (rotateTrack !is null)
        {
            for (uint i=0; i<rotateTrack.numKeyFrames; ++i)
            {
                AnimationKeyFrame kf(rotateTrack.keyFrames[i]);
                rotateNode.rotation = kf.rotation;
                Quaternion wq = rotateNode.worldRotation;
                wq = flipZ_Rot * wq;
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
                kf.position = flipZ_Rot * kf.position;
                translateTrack.keyFrames[i] = kf;
            }
        }
    }

    if (translateTrack !is null)
    {
        translateNode.position = translateTrack.keyFrames[0].position;
        Vector3 t_ws1 = translateNode.worldPosition;
        translateNode.position = pelvisOrign;
        Vector3 t_ws2 = translateNode.worldPosition;
        startFromOrigin = t_ws1 - t_ws2;
    }

    outKeys.Resize(translateTrack.numKeyFrames);

    float firstRotateFromRoot = 0;
    if (rotateTrack !is null)
    {
        for (uint i=0; i<rotateTrack.numKeyFrames; ++i)
        {
            Quaternion q = GetRotationInXZPlane(rotateNode, rotateBoneInitQ, rotateTrack.keyFrames[i].rotation);
            if (d_log)
            {
                if (i == 0 || i == rotateTrack.numKeyFrames - 1)
                    Print("frame=" + String(i) + " rotation from identical in xz plane=" + q.eulerAngles.ToString());
            }
            if (i == 0)
                firstRotateFromRoot = q.eulerAngles.y;
        }
    }

    // process rotate key frames first
    if ((motionFlag & kMotion_R != 0) && rotateTrack !is null)
    {
        Quaternion lastRot = rotateTrack.keyFrames[0].rotation;
        float rotateFromStart = cutRotation ? firstRotateFromRoot : 0;
        for (uint i=0; i<rotateTrack.numKeyFrames; ++i)
        {
            AnimationKeyFrame kf(rotateTrack.keyFrames[i]);
            Quaternion q = GetRotationInXZPlane(rotateNode, lastRot, kf.rotation);
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

    originFlag &= (~kMotion_R);
    if (originFlag != 0 && translateTrack !is null)
    {
        Vector3 firstKeyPos = translateTrack.keyFrames[0].position;
        translateNode.position = firstKeyPos;
        Vector3 currentWS = translateNode.worldPosition;
        Vector3 oldWS = currentWS;

        if (originFlag & kMotion_X != 0)
            currentWS.x = pelvisOrign.x;
        if (originFlag & kMotion_Y != 0)
            currentWS.y = pelvisOrign.y;
        if (originFlag & kMotion_Z != 0)
            currentWS.z = pelvisOrign.z;

        translateNode.worldPosition = currentWS;
        Vector3 currentLS = translateNode.position;
        Vector3 originDiffLS = currentLS - firstKeyPos;

        for (uint i=0; i<translateTrack.numKeyFrames; ++i)
        {
            AnimationKeyFrame kf(translateTrack.keyFrames[i]);
            Vector3 old = kf.position;
            kf.position += originDiffLS;
            translateTrack.keyFrames[i] = kf;
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
}

Animation@ CreateAnimation(const String&in originAnimationName, const String&in name, int start_frame, int num_of_frames)
{
    Animation@ originAnimation = FindAnimation(originAnimationName);
    if (originAnimation is null)
        return null;
    Animation@ anim = Animation();
    anim.name = GetAnimationName(name);
    anim.animationName = name;
    anim.length = float(num_of_frames) * SEC_PER_FRAME;
    for (uint i=0; i<skeleton.numBones; ++i)
    {
        AnimationTrack@ originTrack = originAnimation.tracks[skeleton.bones[i].name];
        if (originTrack is null)
            continue;
        AnimationTrack@ track = anim.CreateTrack(skeleton.bones[i].name);
        track.channelMask = originTrack.channelMask;
        for (int j=start_frame; j<start_frame+num_of_frames; ++j)
        {
            AnimationKeyFrame kf(originTrack.keyFrames[j]);
            kf.time = float(j-start_frame) * SEC_PER_FRAME;
            track.AddKeyFrame(kf);
        }
    }
    cache.AddManualResource(anim);
    return anim;
}

void AssetPostProcess()
{
    @skeleton = null;
    @rotateNode = null;
    @translateNode = null;
    @processNode = null;
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
    AddFloatAnimationTrigger(name, counterStart, TIME_SCALE, 0.25f);
    AddFloatAnimationTrigger(name, counterEnd, TIME_SCALE, 1.0f);
    AddIntAnimationTrigger(name, counterStart, COUNTER_CHECK, 1);
    AddIntAnimationTrigger(name, counterEnd, COUNTER_CHECK, 0);
    AddAttackTrigger(name, attackStart, attackEnd, attackBone);
}
// ==============================================
//
//    Root Motion Class
//
// ==============================================

const int LAYER_MOVE = 0;
const int LAYER_ATTACK = 1;

enum AttackType
{
    ATTACK_PUNCH,
    ATTACK_KICK,
};

void PlayAnimation(AnimationController@ ctrl, const String&in name, uint layer = LAYER_MOVE, bool loop = false, float blendTime = 0.1f, float startTime = 0.0f, float speed = 1.0f)
{
    //Print("PlayAnimation " + name + " loop=" + loop + " blendTime=" + blendTime + " startTime=" + startTime + " speed=" + speed);
    ctrl.StopLayer(layer, blendTime);
    ctrl.PlayExclusive(name, layer, loop, blendTime);
    ctrl.SetTime(name, startTime);
    ctrl.SetSpeed(name, speed);
}

int FindMotionIndex(const Array<Motion@>&in motions, const String&in name)
{
    for (uint i=0; i<motions.length; ++i)
    {
        if (motions[i].name == name)
            return i;
    }
    return -1;
}

void FillAnimationWithCurrentPose(Animation@ anim, Node@ _node)
{
    Array<String> boneNames =
    {
        "Bip01_$AssimpFbx$_Translation",
        "Bip01_$AssimpFbx$_PreRotation",
        "Bip01_$AssimpFbx$_Rotation",
        "Bip01_Pelvis",
        "Bip01_Spine",
        "Bip01_Spine1",
        "Bip01_Spine2",
        "Bip01_Spine3",
        "Bip01_Neck",
        "Bip01_Head",
        "Bip01_L_Thigh",
        "Bip01_L_Calf",
        "Bip01_L_Foot",
        "Bip01_R_Thigh",
        "Bip01_R_Calf",
        "Bip01_R_Foot",
        "Bip01_L_Clavicle",
        "Bip01_L_UpperArm",
        "Bip01_L_Forearm",
        "Bip01_L_Hand",
        "Bip01_R_Clavicle",
        "Bip01_R_UpperArm",
        "Bip01_R_Forearm",
        "Bip01_R_Hand"
    };

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

int GetAttackType(const String&in name)
{
    if (name.Contains("Foot") || name.Contains("Calf"))
        return ATTACK_KICK;
    return ATTACK_PUNCH;
}

void DebugDrawDirection(DebugRenderer@ debug, Node@ _node, const Quaternion&in rotation, const Color&in color, float radius = 1.0, float yAdjust = 0)
{
    Vector3 dir = rotation * Vector3(0, 0, 1);
    float angle = Atan2(dir.x, dir.z);
    DebugDrawDirection(debug, _node, angle, color, radius, yAdjust);
}

void DebugDrawDirection(DebugRenderer@ debug, Node@ _node, float angle, const Color&in color, float radius = 1.0, float yAdjust = 0)
{
    Vector3 start = _node.worldPosition;
    start.y += yAdjust;
    Vector3 end = start + Vector3(Sin(angle) * radius, 0, Cos(angle) * radius);
    debug.AddLine(start, end, color, false);
}

void SendAnimationTriger(Node@ _node, const StringHash&in nameHash, int value = 0)
{
    VariantMap anim_data;
    anim_data[NAME] = nameHash;
    anim_data[VALUE] = value;
    VariantMap data;
    data[DATA] = anim_data;
    _node.SendEvent("AnimationTrigger", data);
}

Vector4 GetTargetTransform(Node@ baseNode, Motion@ alignMotion, Motion@ baseMotion)
{
    float r1 = alignMotion.GetStartRot();
    float r2 = baseMotion.GetStartRot();
    Vector3 s1 = alignMotion.GetStartPos();
    Vector3 s2 = baseMotion.GetStartPos();

    float baseYaw = baseNode.worldRotation.eulerAngles.y;
    float targetRotation = baseYaw + (r1 - r2);
    Vector3 diff_ws = Quaternion(0, baseYaw - r2, 0) * (s1 - s2);
    Vector3 targetPosition = baseNode.worldPosition + diff_ws;

    if (d_log)
    {
        Print("------------------------------------------------------------------------------------------------------------------------------------------------");
        Print("GetTargetTransform align-motion=" + alignMotion.name + " base-motion=" + baseMotion.name);
        Print("GetTargetTransform base=" + baseNode.name + " align-start-pos=" + s1.ToString() + " base-start-pos=" + s2.ToString() + " p-diff=" + (s1 - s2).ToString());
        Print("baseYaw=" + baseYaw + " targetRotation=" + targetRotation + " align-start-rot=" + r1 + " base-start-rot=" + r2 + " r-diff=" + (r1 - r2));
        Print("basePosition=" + baseNode.worldPosition.ToString() + " diff_ws=" + diff_ws.ToString() + " targetPosition=" + targetPosition.ToString());
        Print("------------------------------------------------------------------------------------------------------------------------------------------------");
    }

    return Vector4(targetPosition.x,  targetPosition.y, targetPosition.z, targetRotation);
}

class Motion
{
    String                  name;
    String                  animationName;
    StringHash              nameHash;

    Animation@              animation;
    Array<Vector4>          motionKeys;
    float                   endTime;
    bool                    looped;

    Vector4                 startFromOrigin;

    float                   endDistance;

    int                     endFrame;
    int                     motionFlag;
    int                     allowMotion;

    float                   rotateAngle = 361;

    bool                    processed = false;

    Motion()
    {
    }

    Motion(const Motion&in other)
    {
        animationName = other.animationName;
        animation = other.animation;
        motionKeys = other.motionKeys;
        endTime = other.endTime;
        looped = other.looped;
        startFromOrigin = other.startFromOrigin;
        endDistance = other.endDistance;
        endFrame = other.endFrame;
        motionFlag = other.motionFlag;
        allowMotion = other.allowMotion;
    }

    void SetName(const String&in _name)
    {
        name = _name;
        nameHash = StringHash(name);
    }

    ~Motion()
    {
        animation = null;
        cache.ReleaseResource("Animation", animationName);
    }

    void Process()
    {
        if (processed)
            return;
        uint startTime = time.systemTime;
        this.animationName = GetAnimationName(this.name);
        this.animation = cache.GetResource("Animation", animationName);
        if (this.animation is null)
            return;

        gMotionMgr.memoryUse += this.animation.memoryUse;
        rotateAngle = ProcessAnimation(animationName, motionFlag, allowMotion, rotateAngle, motionKeys, startFromOrigin);

        SetEndFrame(endFrame);
        Vector4 v = motionKeys[0];
        Vector4 diff = motionKeys[endFrame - 1] - motionKeys[0];
        endDistance = Vector3(diff.x, diff.y, diff.z).length;
        processed = true;
        //if (d_log)
        Print("Motion " + name + " endDistance="  + endDistance + " startFromOrigin=" + startFromOrigin.ToString()  + " timeCost=" + String(time.systemTime - startTime) + " ms");
    }

    void SetEndFrame(int frame)
    {
        endFrame = frame;
        if (endFrame < 0)
        {
            endFrame = motionKeys.length - 1;
            endTime = this.animation.length;
        }
        else
            endTime = float(endFrame) * SEC_PER_FRAME;
    }

    void GetMotion(float t, float dt, bool loop, Vector4& out out_motion)
    {
        if (motionKeys.empty)
            return;

        float future_time = t + dt;
        if (future_time > animation.length && loop) {
            Vector4 t1 = Vector4(0,0,0,0);
            Vector4 t2 = Vector4(0,0,0,0);
            GetMotion(t, animation.length - t, false, t1);
            GetMotion(0, t + dt - animation.length, false, t2);
            out_motion = t1 + t2;
        }
        else
        {
            Vector4 k1 = GetKey(t);
            Vector4 k2 = GetKey(future_time);
            out_motion = k2 - k1;
        }
    }

    Vector4 GetKey(float t)
    {
        if (motionKeys.empty)
            return Vector4(0, 0, 0, 0);

        uint i = uint(t * FRAME_PER_SEC);
        if (i >= motionKeys.length)
            i = motionKeys.length - 1;
        Vector4 k1 = motionKeys[i];
        uint next_i = i + 1;
        if (next_i >= motionKeys.length)
            next_i = motionKeys.length - 1;
        if (i == next_i)
            return k1;
        Vector4 k2 = motionKeys[next_i];
        float a = t*FRAME_PER_SEC - float(i);
        // float a =  (t - float(i)*SEC_PER_FRAME)/SEC_PER_FRAME;
        return k1.Lerp(k2, a);
    }

    Vector3 GetFuturePosition(Character@ object, float t)
    {
        Vector4 motionOut = GetKey(t);
        Node@ _node = object.GetNode();
        if (looped)
            return _node.worldRotation * Vector3(motionOut.x, motionOut.y, motionOut.z) + _node.worldPosition;
        else
            return Quaternion(0, object.motion_startRotation, 0) * Vector3(motionOut.x, motionOut.y, motionOut.z) + object.motion_startPosition;
    }

    float GetFutureRotation(Character@ object, float t)
    {
        return AngleDiff(object.GetNode().worldRotation.eulerAngles.y + GetKey(t).w);
    }

    void Start(Character@ object, float localTime = 0.0f, float blendTime = 0.1, float speed = 1.0f)
    {
        object.PlayAnimation(animationName, LAYER_MOVE, looped, blendTime, localTime, speed);
        InnerStart(object);
    }

    void InnerStart(Character@ object)
    {
        object.motion_startPosition = object.GetNode().worldPosition;
        object.motion_startRotation = object.GetNode().worldRotation.eulerAngles.y;
        object.motion_deltaRotation = 0;
        object.motion_deltaPosition = Vector3(0, 0, 0);
        object.motion_translateEnabled = true;
        object.motion_rotateEnabled = true;
        // Print("motion " + animationName + " start-position=" + object.motion_startPosition.ToString() + " start-rotation=" + object.motion_startRotation);
    }

    bool Move(Character@ object, float dt)
    {
        AnimationController@ ctrl = object.animCtrl;
        Node@ _node = object.GetNode();
        float localTime = ctrl.GetTime(animationName);

        if (looped)
        {
            Vector4 motionOut = Vector4(0, 0, 0, 0);
            GetMotion(localTime, dt, looped, motionOut);

            if (object.motion_rotateEnabled)
                _node.Yaw(motionOut.w);

            if (object.motion_translateEnabled)
            {
                Vector3 tLocal(motionOut.x, motionOut.y, motionOut.z);
                tLocal = tLocal * ctrl.GetWeight(animationName);
                Vector3 tWorld = _node.worldRotation * tLocal + _node.worldPosition + object.motion_deltaPosition;
                object.MoveTo(tWorld, dt);
            }
        }
        else
        {
            Vector4 motionOut = GetKey(localTime);
            if (object.motion_rotateEnabled)
                _node.worldRotation = Quaternion(0, object.motion_startRotation + motionOut.w + object.motion_deltaRotation, 0);

            if (object.motion_translateEnabled)
            {
                Vector3 tWorld = Quaternion(0, object.motion_startRotation, 0) * Vector3(motionOut.x, motionOut.y, motionOut.z) + object.motion_startPosition + object.motion_deltaPosition;
                //Print("tWorld=" + tWorld.ToString() + " cur-pos=" + object.GetNode().worldPosition.ToString() + " localTime=" + localTime);
                object.MoveTo(tWorld, dt);
            }
        }
        return localTime >= endTime;
    }

    void DebugDraw(DebugRenderer@ debug, Character@ object)
    {
        Node@ _node = object.GetNode();
        if (looped) {
            Vector4 tFinnal = GetKey(endTime);
            Vector3 tLocal(tFinnal.x, tFinnal.y, tFinnal.z);
            debug.AddLine(_node.worldRotation * tLocal + _node.worldPosition, _node.worldPosition, Color(0.5f, 0.5f, 0.7f), false);
        }
        else {
            Vector4 tFinnal = GetKey(endTime);
            Vector3 tMotionEnd = Quaternion(0, object.motion_startRotation, 0) * Vector3(tFinnal.x, tFinnal.y, tFinnal.z);
            debug.AddLine(tMotionEnd + object.motion_startPosition,  object.motion_startPosition, Color(0.5f, 0.5f, 0.7f), false);
            DebugDrawDirection(debug, _node, object.motion_startRotation + tFinnal.w, GREEN, 2.0);
        }
    }

    Vector3 GetStartPos()
    {
        return Vector3(startFromOrigin.x, startFromOrigin.y, startFromOrigin.z);
    }

    float GetStartRot()
    {
        return -rotateAngle;
    }
};

class AttackMotion
{
    Motion@                  motion;

    // ==============================================
    //   ATTACK VALUES
    // ==============================================

    float                   impactTime;
    float                   impactDist;;
    Vector3                 impactPosition;
    int                     type;
    String                  boneName;

    AttackMotion(const String&in name, int impactFrame, int _type, const String&in bName)
    {
        @motion = gMotionMgr.FindMotion(name);
        impactTime = impactFrame * SEC_PER_FRAME;
        Vector4 k = motion.motionKeys[impactFrame];
        impactPosition = Vector3(k.x, k.y, k.z);
        impactDist = impactPosition.length;
        type = _type;
        boneName = bName;
    }

    int opCmp(const AttackMotion&in obj)
    {
        if (impactDist > obj.impactDist)
            return 1;
        else if (impactDist < obj.impactDist)
            return -1;
        else
            return 0;
    }
};

class MotionManager
{
    Array<Motion@>          motions;
    Array<String>           animations;
    uint                    assetProcessTime;
    int                     memoryUse;
    int                     processedMotions;
    int                     processedAnimations;

    MotionManager()
    {
        Print("MotionManager");
    }

    ~MotionManager()
    {
        Print("~MotionManager");
    }

    Motion@ FindMotion(StringHash nameHash)
    {
        for (uint i=0; i<motions.length; ++i)
        {
            if (motions[i].nameHash == nameHash)
                return motions[i];
        }
        return null;
    }

    Motion@ FindMotion(const String&in name)
    {
        Motion@ m = FindMotion(StringHash(name));
        if (m is null)
            log.Error("FindMotion Could not find " + name);
        return m;
    }

    void Start()
    {
        assetProcessTime = time.systemTime;
        AssetPreProcess();
        CreateBruceMotions();
        CreateThugMotions();
        // CreateCatwomanMotions();
    }

    void Stop()
    {
        motions.Clear();
    }

    void Finish()
    {
        PostProcess();
        AssetPostProcess();
        Print("************************************************************************************************");
        Print("Motion Process time-cost=" + String(time.systemTime - assetProcessTime) + " ms num-of-motions=" + motions.length + " memory-use=" + String(memoryUse/1024) + " KB");
        Print("************************************************************************************************");
    }

    void PostProcess()
    {
        uint t = time.systemTime;
        AddThugAnimationTriggers();
        AddBruceAnimationTriggers();
        AddCatwomanAnimationTriggers();
        Print("MotionManager::PostProcess time-cost=" + (time.systemTime - t) + " ms");
    }

    Motion@ CreateMotion(const String&in name, int motionFlag = kMotion_XZR, int allowMotion = kMotion_XZR,  int endFrame = -1, bool loop = false, float rotateAngle = 361)
    {
        Motion@ motion = Motion();
        motion.SetName(name);
        motion.motionFlag = motionFlag;
        motion.allowMotion = allowMotion;
        motion.looped = loop;
        motion.endFrame = endFrame;
        motion.rotateAngle = rotateAngle;
        motions.Push(motion);
        return motion;
    }

    void AddAnimation(const String&in animation)
    {
        animations.Push(animation);
    }

    bool Update(float dt)
    {
        if (processedMotions >= int(motions.length) && processedAnimations >= int(animations.length))
            return true;

        uint t = time.systemTime;
        int len = int(motions.length);
        for (int i=processedMotions; i<len; ++i)
        {
            motions[i].Process();
            ++processedMotions;
            int time_diff = int(time.systemTime - t);
            if (time_diff >= PROCESS_TIME_PER_FRAME)
                break;
        }

        len = int(animations.length);
        for (int i=processedAnimations; i<len; ++i)
        {
            cache.GetResource("Animation", GetAnimationName(animations[i]));
            ++processedAnimations;
            int time_diff = int(time.systemTime - t);
            if (time_diff >= PROCESS_TIME_PER_FRAME)
                break;
        }

        Print("MotionManager Process this frame time=" + (time.systemTime - t) + " ms " + " processedMotions=" + processedMotions + " processedAnimations=" + processedAnimations);
        return processedMotions >= int(motions.length) && processedAnimations >= int(animations.length);
    }

    void ProcessAll()
    {
        for (uint i=0; i<motions.length; ++i)
            motions[i].Process();
    }

    void AddCounterMotions(const String&in counter_prefix)
    {
        CreateMotion(counter_prefix + "Counter_Arm_Back_01");
        CreateMotion(counter_prefix + "Counter_Arm_Back_02");
        CreateMotion(counter_prefix + "Counter_Arm_Back_03");
        CreateMotion(counter_prefix + "Counter_Arm_Back_05");
        CreateMotion(counter_prefix + "Counter_Arm_Back_06");

        CreateMotion(counter_prefix + "Counter_Arm_Back_Weak_01");
        CreateMotion(counter_prefix + "Counter_Arm_Back_Weak_02");
        CreateMotion(counter_prefix + "Counter_Arm_Back_Weak_03");

        CreateMotion(counter_prefix + "Counter_Arm_Front_01");
        CreateMotion(counter_prefix + "Counter_Arm_Front_02");
        CreateMotion(counter_prefix + "Counter_Arm_Front_03");
        CreateMotion(counter_prefix + "Counter_Arm_Front_04");
        CreateMotion(counter_prefix + "Counter_Arm_Front_05");
        CreateMotion(counter_prefix + "Counter_Arm_Front_06");
        CreateMotion(counter_prefix + "Counter_Arm_Front_07");
        CreateMotion(counter_prefix + "Counter_Arm_Front_08");
        CreateMotion(counter_prefix + "Counter_Arm_Front_09");
        CreateMotion(counter_prefix + "Counter_Arm_Front_10");
        CreateMotion(counter_prefix + "Counter_Arm_Front_13");
        CreateMotion(counter_prefix + "Counter_Arm_Front_14");

        CreateMotion(counter_prefix + "Counter_Arm_Front_Weak_02");
        CreateMotion(counter_prefix + "Counter_Arm_Front_Weak_03");
        CreateMotion(counter_prefix + "Counter_Arm_Front_Weak_04");

        CreateMotion(counter_prefix + "Counter_Leg_Back_01");
        CreateMotion(counter_prefix + "Counter_Leg_Back_02");
        CreateMotion(counter_prefix + "Counter_Leg_Back_03");
        CreateMotion(counter_prefix + "Counter_Leg_Back_04");
        CreateMotion(counter_prefix + "Counter_Leg_Back_05");

        CreateMotion(counter_prefix + "Counter_Leg_Back_Weak_01");
        CreateMotion(counter_prefix + "Counter_Leg_Back_Weak_03");

        CreateMotion(counter_prefix + "Counter_Leg_Front_01");
        CreateMotion(counter_prefix + "Counter_Leg_Front_02");
        CreateMotion(counter_prefix + "Counter_Leg_Front_03");
        CreateMotion(counter_prefix + "Counter_Leg_Front_04");
        CreateMotion(counter_prefix + "Counter_Leg_Front_05");
        CreateMotion(counter_prefix + "Counter_Leg_Front_06");
        CreateMotion(counter_prefix + "Counter_Leg_Front_07");
        CreateMotion(counter_prefix + "Counter_Leg_Front_08");
        CreateMotion(counter_prefix + "Counter_Leg_Front_09");

        CreateMotion(counter_prefix + "Counter_Leg_Front_Weak");
        CreateMotion(counter_prefix + "Counter_Leg_Front_Weak_01");
        CreateMotion(counter_prefix + "Counter_Leg_Front_Weak_02");
    }
};


MotionManager@ gMotionMgr = MotionManager();

Motion@ Global_CreateMotion(const String&in name, int motionFlag = kMotion_XZR, int allowMotion = kMotion_XZR,  int endFrame = -1, bool loop = false, float rotateAngle = 361)
{
    return gMotionMgr.CreateMotion(name, motionFlag, allowMotion, endFrame, loop, rotateAngle);
}

void Global_AddAnimation(const String&in name)
{
    gMotionMgr.AddAnimation(name);
}
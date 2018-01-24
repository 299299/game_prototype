// ==============================================
//
//    Root Motion Class
//
// ==============================================

void Global_PlayAnimation(AnimationController@ ctrl, const String&in name, uint layer = LAYER_MOVE, bool loop = false, float blendTime = 0.1f, float startTime = 0.0f, float speed = 1.0f)
{
    //LogPrint("PlayAnimation " + name + " loop=" + loop + " blendTime=" + blendTime + " startTime=" + startTime + " speed=" + speed);
    ctrl.StopLayer(layer, blendTime);
    ctrl.PlayExclusive(name, layer, loop, blendTime);
    ctrl.SetTime(name, startTime);
    ctrl.SetSpeed(name, speed);
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

void SendAnimationTriger(Node@ _node, const StringHash&in nameHash, int value = 0)
{
    VariantMap anim_data;
    anim_data[NAME] = nameHash;
    anim_data[VALUE] = value;
    VariantMap data;
    data[DATA] = anim_data;
    _node.SendEvent("AnimationTrigger", data);
}

Vector4 GetTargetTransform(const Vector3& basePosition, float baseRotation, const Vector3& baseMotionPosition, float baseMotionRotation, Motion@ alignMotion)
{
    float r1 = alignMotion.GetStartRot();
    float r2 = baseMotionRotation;
    Vector3 s1 = alignMotion.GetStartPos();
    Vector3 s2 = baseMotionPosition;

    float baseYaw = baseRotation;
    float targetRotation = baseYaw + (r1 - r2);
    Vector3 diff_ws = Quaternion(0, baseYaw - r2, 0) * (s1 - s2);
    Vector3 targetPosition = basePosition + diff_ws;

    if (d_log)
    {
        LogPrint("------------------------------------------------------------------------------------------------------------------------------------------------");
        LogPrint("GetTargetTransform align-motion=" + alignMotion.name);
        LogPrint("GetTargetTransform align-start-pos=" + s1.ToString() + " base-start-pos=" + s2.ToString() + " p-diff=" + (s1 - s2).ToString());
        LogPrint("baseYaw=" + baseYaw + " targetRotation=" + targetRotation + " align-start-rot=" + r1 + " base-start-rot=" + r2 + " r-diff=" + (r1 - r2));
        LogPrint("basePosition=" + basePosition.ToString() + " diff_ws=" + diff_ws.ToString() + " targetPosition=" + targetPosition.ToString());
        LogPrint("------------------------------------------------------------------------------------------------------------------------------------------------");
    }

    return Vector4(targetPosition.x,  targetPosition.y, targetPosition.z, targetRotation);
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
        LogPrint("------------------------------------------------------------------------------------------------------------------------------------------------");
        LogPrint("GetTargetTransform align-motion=" + alignMotion.name + " base-motion=" + baseMotion.name);
        LogPrint("GetTargetTransform base=" + baseNode.name + " align-start-pos=" + s1.ToString() + " base-start-pos=" + s2.ToString() + " p-diff=" + (s1 - s2).ToString());
        LogPrint("baseYaw=" + baseYaw + " targetRotation=" + targetRotation + " align-start-rot=" + r1 + " base-start-rot=" + r2 + " r-diff=" + (r1 - r2));
        LogPrint("basePosition=" + baseNode.worldPosition.ToString() + " diff_ws=" + diff_ws.ToString() + " targetPosition=" + targetPosition.ToString());
        LogPrint("------------------------------------------------------------------------------------------------------------------------------------------------");
    }

    return Vector4(targetPosition.x,  targetPosition.y, targetPosition.z, targetRotation);
}

float GetTargetTransformErrorSqr(Node@ alignNode, Node@ baseNode, Motion@ alignMotion, Motion@ baseMotion)
{
    Vector4 v4 = GetTargetTransform(baseNode, alignMotion, baseMotion);
    Vector3 v3 = Vector3(v4.x, v4.y, v4.z) - alignNode.worldPosition;
    v3.y = 0;
    return v3.lengthSquared;
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

    float                   maxHeight;
    bool                    processed = false;

    float                   dockAlignTime;
    int                     dockAlignFrame;
    Vector3                 dockAlignOffset;
    String                  dockAlignBoneName;

    int                     type;
    float                   dockDist;

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
        // LogPrint("Release animation " + this.name);
        animation = null;
        cache.ReleaseResource("Animation", animationName);
    }

    void Process()
    {
        if (processed)
            return;
        uint startTime = time.systemTime;
        this.animationName = GetAnimationName(this.name);
        if (cache.GetExistingResource("Animation", animationName) !is null)
            LogPrint("Error " + this.name + " already loaded !!!");

        this.animation = cache.GetResource("Animation", animationName);
        if (this.animation is null)
            return;

        gMotionMgr.memoryUse += this.animation.memoryUse;
        ProcessAnimation(curRig, animationName, motionFlag, allowMotion, motionKeys, startFromOrigin);
        SetEndFrame(endFrame);

        if (!dockAlignBoneName.empty)
        {
            Vector3 v = GetBoneWorldPosition(curRig, animationName, dockAlignBoneName, dockAlignTime);
            // LogPrint(this.name + " bone " + dockAlignBoneName + " world-pos=" + v.ToString() + " at time:" + dockAlignTime);
            dockAlignOffset += v;

            Vector4 k = motionKeys[dockAlignFrame];
            Vector3 v3 = Vector3(k.x, 0, k.z);
            dockDist = v3.length;
        }

        if (!motionKeys.empty)
        {
            Vector4 v = motionKeys[0];
            Vector4 diff = motionKeys[endFrame - 1] - motionKeys[0];
            endDistance = Vector3(diff.x, diff.y, diff.z).length;
        }

        maxHeight = -9999;
        for (uint i=0; i<motionKeys.length; ++i)
        {
            if (motionKeys[i].y > maxHeight)
                maxHeight = motionKeys[i].y;
        }

        processed = true;

        if (d_log)
        LogPrint("Motion " + name + " endDistance="  + endDistance +
                 " startFromOrigin=" + startFromOrigin.ToString()  +
                 " maxHeight=" + maxHeight +
                 " timeCost=" + String(time.systemTime - startTime) + " ms");
    }

    void SetDockAlign(const String&in boneName, int alignFrame, const Vector3&in offset = Vector3::ZERO)
    {
        dockAlignBoneName = boneName;
        dockAlignOffset = offset;
        dockAlignTime = float(alignFrame) * SEC_PER_FRAME;
        dockAlignFrame = alignFrame;
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
        return k1.Lerp(k2, a);
    }

    Vector3 GetFuturePosition(Character@ object, float t)
    {
        Vector4 motionOut = GetKey(t);
        Node@ _node = object.GetNode();
        if (looped)
            return _node.worldRotation * Vector3(motionOut.x, motionOut.y, motionOut.z) + _node.worldPosition + object.motion_deltaPosition;
        else
            return Quaternion(0, object.motion_rotation + object.motion_deltaRotation, 0) * Vector3(motionOut.x, motionOut.y, motionOut.z) + object.motion_startPosition + object.motion_deltaPosition;
    }

    Vector3 GetKeyPosition(Character@ object, float t)
    {
        Vector4 motionOut = GetKey(t);
        Node@ _node = object.GetNode();
        return _node.worldRotation * Vector3(motionOut.x, motionOut.y, motionOut.z) + _node.worldPosition;
    }

    float GetFutureRotation(Character@ object, float t)
    {
        if (looped)
            return AngleDiff(object.GetNode().worldRotation.eulerAngles.y + object.motion_deltaRotation + GetKey(t).w);
        else
            return AngleDiff(object.motion_rotation + object.motion_deltaRotation + GetKey(t).w);
    }

    void Start(Character@ object, float localTime = 0.0f, float blendTime = 0.1, float speed = 1.0f)
    {
        object.PlayAnimation(animationName, LAYER_MOVE, looped, blendTime, localTime, speed);
        InnerStart(object);
    }

    float GetDockAlignTime()
    {
        return dockAlignBoneName.empty ? endTime : dockAlignTime;
    }

    Vector3 GetDockAlignPositionAtTime(Character@ object, float targetRotation, float t)
    {
        Node@ _node = object.GetNode();
        Vector4 motionOut = GetKey(t);
        Vector3 motionPos = Quaternion(0, targetRotation, 0) * Vector3(motionOut.x, motionOut.y, motionOut.z) + object.motion_startPosition + object.motion_deltaPosition;

        // gDebugMgr.AddCross(motionPos, 5.0f, BLACK, 5.0f);

        Vector3 offsetPos = Quaternion(0, targetRotation + motionOut.w, 0) * dockAlignOffset;

        // Print("GetDockAlignPositionAtTime t=" + t + " motion=" + motionOut.ToString());

        return motionPos + offsetPos;
    }

    void InnerStart(Character@ object)
    {
        object.motion_startPosition = object.GetNode().worldPosition;
        object.motion_startRotation = object.GetNode().worldRotation.eulerAngles.y;
        object.motion_rotation = object.motion_startRotation;
        object.motion_deltaRotation = 0;
        object.motion_deltaPosition = Vector3(0, 0, 0);
        object.motion_velocity = Vector3(0, 0, 0);
        object.motion_translateEnabled = true;
        object.motion_rotateEnabled = true;
        if (d_log)
            LogPrint("motion " + animationName + " start start-position=" + object.motion_startPosition.ToString() + " start-rotation=" + object.motion_startRotation);
    }

    int Move(Character@ object, float dt)
    {
        AnimationController@ ctrl = object.animCtrl;
        Node@ _node = object.GetNode();
        float localTime = ctrl.GetTime(animationName);
        float speed = ctrl.GetSpeed(animationName);
        float absSpeed = Abs(speed);

        if (absSpeed < 0.001)
            return 0;

        // dt *= absSpeed;
        if (looped || speed < 0)
        {
            Vector4 motionOut = Vector4(0, 0, 0, 0);
            GetMotion(localTime, dt, looped, motionOut);
            if (!looped)
            {
                if (localTime < SEC_PER_FRAME)
                    motionOut = Vector4(0, 0, 0, 0);
            }

            if (object.motion_rotateEnabled)
                _node.Yaw(motionOut.w);

            if (object.motion_translateEnabled)
            {
                Vector3 tLocal(motionOut.x, motionOut.y, motionOut.z);
                Vector3 tWorld = _node.worldRotation * tLocal;

                /*if (object.physicsType == 0)
                {
                    object.MoveTo(tWorld + _node.worldPosition + object.motion_velocity * dt, dt);
                }
                else
                {
                    object.SetVelocity(tWorld / dt + object.motion_velocity);
                }*/
                object.MoveTo(tWorld + _node.worldPosition + object.motion_velocity * dt, dt);
            }
            else
            {
                object.SetVelocity(Vector3::ZERO);
            }

            if (speed < 0 && localTime < 0.001)
                return 1;

            return 0;
        }
        else
        {
            Vector4 motionOut = GetKey(localTime);
            if (object.motion_rotateEnabled)
                _node.worldRotation = Quaternion(0, object.motion_startRotation + motionOut.w + object.motion_deltaRotation, 0);

            if (object.motion_translateEnabled)
            {
                /*if (object.physicsType == 0)
                {
                    object.motion_deltaPosition += object.motion_velocity * dt;
                    Vector3 tWorld = Quaternion(0, object.motion_rotation, 0) * Vector3(motionOut.x, motionOut.y, motionOut.z) + object.motion_startPosition + object.motion_deltaPosition;
                    object.MoveTo(tWorld, dt);
                }
                else
                {
                    Vector3 tWorld1 = Quaternion(0, object.motion_rotation, 0) * Vector3(motionOut.x, motionOut.y, motionOut.z);
                    motionOut = GetKey(localTime + dt);
                    Vector3 tWorld2 = Quaternion(0, object.motion_rotation, 0) * Vector3(motionOut.x, motionOut.y, motionOut.z);
                    Vector3 vel = (tWorld2 - tWorld1) / dt;
                    object.SetVelocity(vel + object.motion_velocity);
                }*/

                object.motion_deltaPosition += object.motion_velocity * dt;
                Vector3 tWorld = Quaternion(0, object.motion_rotation, 0) * Vector3(motionOut.x, motionOut.y, motionOut.z) + object.motion_startPosition + object.motion_deltaPosition;
                object.MoveTo(tWorld, dt);
            }
            else
            {
                object.SetVelocity(Vector3::ZERO);
            }

            if (!dockAlignBoneName.empty)
            {
                if (localTime < dockAlignTime && (localTime + dt) > dockAlignTime)
                    return 2;
            }

            bool bFinished = (speed > 0) ? localTime >= endTime : (localTime < 0.001);
            return bFinished ? 1 : 0;
        }
    }

    void DebugDraw(DebugRenderer@ debug, Character@ object)
    {
        Node@ _node = object.GetNode();
        /*
        if (looped) {
            Vector4 tFinnal = GetKey(endTime);
            Vector3 tLocal(tFinnal.x, tFinnal.y, tFinnal.z);
            debug.AddLine(_node.worldRotation * tLocal + _node.worldPosition, _node.worldPosition, Color(0.5f, 0.5f, 0.7f), false);
        }
        else {
            Vector4 tFinnal = GetKey(endTime);
            Vector3 tMotionEnd = Quaternion(0, object.motion_startRotation + object.motion_deltaRotation, 0) * Vector3(tFinnal.x, tFinnal.y, tFinnal.z);
            debug.AddLine(tMotionEnd + object.motion_startPosition,  object.motion_startPosition, Color(0.5f, 0.5f, 0.7f), false);
            DebugDrawDirection(debug, _node, object.motion_startRotation + object.motion_deltaRotation + tFinnal.w, RED, 2.0);
        }
        */

        if (!dockAlignBoneName.empty)
        {
            //Vector3 v = _node.LocalToWorld(dockAlignOffset);
            //debug.AddLine(_node.worldPosition, v, BLUE, false);
            //debug.AddCross(v, 0.5f, GREEN, false);
            debug.AddCross(_node.GetChild(dockAlignBoneName, true).worldPosition, 0.5f, GREEN, false);
            //debug.AddNode(_node.GetChild(dockAlignBoneName, true), 0.25f, false);
        }
    }

    Vector3 GetStartPos()
    {
        return Vector3(startFromOrigin.x, startFromOrigin.y, startFromOrigin.z);
    }

    float GetStartRot()
    {
        return startFromOrigin.w;
    }

    Vector3 GetVelocity()
    {
        if (motionKeys.empty)
            return Vector3(0, 0, 0);
        Vector4 v = motionKeys[motionKeys.length - 1];
        return  Vector3(v.x, v.y, v.z) / endTime;
    }

    int opCmp(const Motion&in obj)
    {
        if (dockDist > obj.dockDist)
            return 1;
        else if (dockDist < obj.dockDist)
            return -1;
        else
            return 0;
    }
};

enum MotionLoadingState
{
    MOTION_LOADING_START = 0,
    MOTION_LOADING_MOTIONS,
    MOTION_LOADING_ANIMATIONS,
    MOTION_LOADING_FINISHED
};

class MotionManager
{
    Array<Motion@>          motions;
    Array<String>           animations;
    uint                    assetProcessTime;
    int                     memoryUse;
    int                     processedMotions;
    int                     processedAnimations;
    int                     state = MOTION_LOADING_START;

    MotionManager()
    {
        LogPrint("MotionManager");
    }

    ~MotionManager()
    {
        LogPrint("~MotionManager");
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
        AddMotions();
        state = MOTION_LOADING_MOTIONS;
    }

    void Stop()
    {
        motions.Clear();
        for (uint i=0; i<animations.length;++i)
            cache.ReleaseResource("Animation", animations[i]);
    }

    void Finish()
    {
        PostProcess();
        AssetPostProcess();
        LogPrint("************************************************************************************************");
        LogPrint("Motion Process time-cost=" + String(time.systemTime - assetProcessTime) + " ms num-of-motions=" + motions.length + " memory-use=" + String(memoryUse/1024) + " KB");
        LogPrint("************************************************************************************************");
    }

    void PostProcess()
    {
        uint t = time.systemTime;
        AddTriggers();
        LogPrint("MotionManager::PostProcess time-cost=" + (time.systemTime - t) + " ms");
    }

    void AddTriggers()
    {
    }

    void AddMotions()
    {
    }

    Motion@ CreateMotion(const String&in name,
        int motionFlag = kMotion_XZR,
        int allowMotion = kMotion_XZR,
        int endFrame = -1,
        bool loop = false)
    {
        Motion@ motion = Motion();
        motion.SetName(name);
        motion.motionFlag = motionFlag;
        motion.allowMotion = allowMotion;
        motion.looped = loop;
        motion.endFrame = endFrame;
        motions.Push(motion);
        return motion;
    }

    void AddAnimation(const String&in animation)
    {
        animations.Push(animation);
    }

    bool Update(float dt)
    {
        if (state == MOTION_LOADING_FINISHED)
            return true;

        if (state == MOTION_LOADING_MOTIONS)
        {
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

            LogPrint("MotionManager Process this frame time=" + (time.systemTime - t) + " ms " + " processedMotions=" + processedMotions);
            if (processedMotions >= len)
                state = MOTION_LOADING_ANIMATIONS;
        }
        else if (state == MOTION_LOADING_ANIMATIONS)
        {
            int len = int(animations.length);
            uint t = time.systemTime;
            for (int i=processedAnimations; i<len; ++i)
            {
                Animation@ anim = cache.GetResource("Animation", GetAnimationName(animations[i]));
                // FixAnimation(anim);
                if (anim is null)
                    LogPrint("Animation load failed --> " + animations[i]);

                ++processedAnimations;
                int time_diff = int(time.systemTime - t);
                if (time_diff >= PROCESS_TIME_PER_FRAME)
                    break;
            }

            LogPrint("MotionManager Process this frame time=" + (time.systemTime - t) + " ms " + " processedAnimations=" + processedAnimations);

            if (processedAnimations >= len)
            {
                state = MOTION_LOADING_FINISHED;
                return true;
            }
        }
        return false;
    }

    void ProcessAll()
    {
        for (uint i=0; i<motions.length; ++i)
            motions[i].Process();
    }
};

Motion@ Global_CreateMotion(const String&in name, int motionFlag = kMotion_XZR, int allowMotion = kMotion_ALL, int endFrame = -1, bool loop = false)
{
    // LogPrint("Global_CreateMotion " + name);
    return gMotionMgr.CreateMotion(name, motionFlag, allowMotion, endFrame, loop);
}

Motion@ Global_CreateMotion(const String&in name, int motionFlag, const String& dockBoneName, int dockFrame, int type = -1)
{
    // LogPrint("Global_CreateMotion " + name);
    Motion@ m = Global_CreateMotion(name, motionFlag);
    m.SetDockAlign(dockBoneName, dockFrame);
    return m;
}

void Global_AddAnimation(const String&in name)
{
    gMotionMgr.AddAnimation(name);
}

void Global_CreateMotion_InFolder(const String&in folder, Array<String>@ preFixToIgnore = null, Array<Motion@>@ motions = null, int motionFlag = kMotion_XZR)
{
    String searchFolder = "MyData/Animations/" + folder;
    if (GetPlatform() == "Android")
    {
        searchFolder = "/apk/" + searchFolder;
    }
    Array<String> animations = fileSystem.ScanDir(searchFolder, "*.ani", SCAN_FILES, false);
    LogPrint("Global_CreateMotion_InFolder folder=" + searchFolder + " animations.size=" + animations.length);
    for (uint i=0; i<animations.length; ++i)
    {
        bool toIgnore = false;
        if (preFixToIgnore !is null)
        {
            for (uint j=0; j<preFixToIgnore.length; ++j)
            {
                if (animations[i].StartsWith(preFixToIgnore[j]))
                {
                    toIgnore = true;
                    break;
                }
            }
        }
        if (toIgnore)
            continue;

        String name = folder + FileNameToMotionName(animations[i]);
        Print("Global_CreateMotion(\"" + name + "\");");
        Motion@ m = Global_CreateMotion(name);
        if (motions !is null)
            motions.Push(m);
    }
}

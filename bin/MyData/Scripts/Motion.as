
const int LAYER_MOVE = 0;
const int LAYER_ATTACK = 1;
const float FRAME_PER_SEC = 30.0f;
const float SEC_PER_FRAME = 1.0f/FRAME_PER_SEC;

void PlayAnimation(AnimationController@ ctrl, const String&in name, uint layer, bool loop, float blendTime = 0.1f, float startTime = 0.0f, float speed = 1.0f)
{
    ctrl.StopLayer(layer, blendTime);
    ctrl.PlayExclusive(name, layer, loop, blendTime);
    ctrl.SetTime(name, startTime);
    ctrl.SetSpeed(name, speed);
}

class Motion
{
    String                  animationName;
    Animation@              animation;
    Array<Vector4>          motionKeys;
    float                   endTime;
    bool                    looped;
    float                   speed;

    Vector3                 startFromOrigin;

    Vector3                 startPosition;
    float                   startRotation;
    Quaternion              startRotationQua;

    Motion()
    {

    }

    ~Motion()
    {
        @animation = null;
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

    void Start(Node@ node, AnimationController@ ctrl, float localTime = 0.0f, float blendTime = 0.1)
    {
        PlayAnimation(ctrl, animationName, LAYER_MOVE, looped, blendTime, localTime, speed);
        startPosition = node.worldPosition;
        startRotationQua = node.worldRotation;
        startRotation = startRotationQua.eulerAngles.y;
    }

    bool Move(float dt, Node@ node, AnimationController@ ctrl)
    {
        float localTime = ctrl.GetTime(animationName);
        if (looped)
        {
            Vector4 motionOut = Vector4(0, 0, 0, 0);
            GetMotion(localTime, dt, looped, motionOut);
            node.Yaw(motionOut.w);
            Vector3 tLocal(motionOut.x, motionOut.y, motionOut.z);
            tLocal = tLocal * ctrl.GetWeight(animationName);
            Vector3 tWorld = node.worldRotation * tLocal + node.worldPosition;
            MoveNode(node, tWorld, dt);
        }
        else
        {
            Vector4 motionOut = GetKey(localTime);
            node.worldRotation = Quaternion(0, startRotation + motionOut.w, 0);
            Vector3 tWorld = startRotationQua * Vector3(motionOut.x, motionOut.y, motionOut.z) + startPosition;
            MoveNode(node, tWorld, dt);
            // Print("key-yaw=" + String(motionOut.w) + " worldRotation=" + node.worldRotation.eulerAngles.ToString());
        }
        return localTime >= endTime;
    }

    Vector3 GetFuturePosition(Node@ node, float t)
    {
        Vector4 motionOut = GetKey(t);
        return node.worldRotation * Vector3(motionOut.x, motionOut.y, motionOut.z) + node.worldPosition;
    }

    Vector3 GetFuturePosition(float t)
    {
        Vector4 motionOut = GetKey(t);
        return startRotationQua * Vector3(motionOut.x, motionOut.y, motionOut.z) + startPosition;
    }

    void MoveNode(Node@ node, const Vector3&in tWorld, float dt)
    {
        RigidBody@ body = node.GetComponent("RigidBody");
        if (body is null)
            node.worldPosition = tWorld;
        else
            body.linearVelocity = (tWorld - node.worldPosition) / dt;
    }

    void DebugDraw(DebugRenderer@ debug, Node@ node)
    {
        if (looped) {
            Vector4 tFinnal = GetKey(endTime);
            Vector3 tLocal(tFinnal.x, tFinnal.y, tFinnal.z);
            debug.AddLine(node.worldRotation * tLocal + node.worldPosition, node.worldPosition, Color(0.5f, 0.5f, 0.7f), false);
        }
        else
            debug.AddLine(GetFuturePosition(endTime),  startPosition, Color(0.5f, 0.5f, 0.7f), false);
    }
};

void DebugDrawDirection(DebugRenderer@ debug, Node@ node, const Quaternion&in rotation, const Color&in color, float radius = 1.0, float yAdjust = 0)
{
    Vector3 dir = rotation * Vector3(0, 0, 1);
    float angle = Atan2(dir.x, dir.z);
    DebugDrawDirection(debug, node, angle, color, radius);
}

void DebugDrawDirection(DebugRenderer@ debug, Node@ node, float angle, const Color&in color, float radius = 1.0, float yAdjust = 0)
{
    Vector3 start = node.worldPosition;
    start.y = yAdjust;
    Vector3 end = start + Vector3(Sin(angle) * radius, 0, Cos(angle) * radius);
    debug.AddLine(start, end, color, false);
}

class AttackMotion
{
    Motion@         motion;
    float           impactTime;
    float           impactDist;
    Vector3         impactPosition;
    Vector2         slowMotionTime;

    AttackMotion(const String&in name, int impactFrame)
    {
        @motion = gMotionMgr.FindMotion(name);
        impactTime = impactFrame * SEC_PER_FRAME;
        Vector4 k = motion.motionKeys[impactFrame];
        impactPosition = Vector3(k.x, k.y, k.z);
        impactDist = impactPosition.length;
        slowMotionTime.x = impactTime - SEC_PER_FRAME * 5;
        slowMotionTime.y = impactTime + SEC_PER_FRAME * 5;
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
    Array<String>           motionNames;
    Array<Motion@>          motions;

    int FindMotionIndex(const String&in name)
    {
        for (uint i=0; i<motionNames.length; ++i)
        {
            if (motionNames[i] == name)
                return i;
        }
        return -1;
    }

    Motion@ FindMotion(const String&in name)
    {
        int i = FindMotionIndex(name);
        if (i < 0)
            return null;

        return motions[i];
    }

    void Start()
    {
        uint startTime = time.systemTime;

        PreProcess();

        // Locomotions
        CreateMotion("BM_Combat_Movement/Turn_Right_90", kMotion_R, 0, kMotion_XZR, 16, false);
        CreateMotion("BM_Combat_Movement/Turn_Right_180", kMotion_R, 0, kMotion_XZR, 28, false);
        CreateMotion("BM_Combat_Movement/Turn_Left_90", kMotion_R, 0, kMotion_XZR, 22, false);
        CreateMotion("BM_Combat_Movement/Walk_Forward", kMotion_Z, 0, kMotion_XZR, -1, true);

        // Evades
        CreateMotion("BM_Movement/Evade_Forward_01", kMotion_XZ, 0, kMotion_XZR, -1, false);
        CreateMotion("BM_Movement/Evade_Back_01", kMotion_XZ, 0, kMotion_XZR, -1, false);

        // Attacks
        // forward
        int foward_motion_flags = kMotion_XZ;
        int foward_allow_motion = kMotion_Z;
        CreateMotion("BM_Attack/Attack_Close_Forward_02", foward_motion_flags, kMotion_R, foward_allow_motion, -1, false);
        for (int i=3; i<=8; ++i)
        {
            CreateMotion("BM_Attack/Attack_Close_Forward_0" + String(i), foward_motion_flags, 0, foward_allow_motion, -1, false);
        }
        CreateMotion("BM_Attack/Attack_Far_Forward", foward_motion_flags, 0, foward_allow_motion, -1, false);
        for (int i=1; i<=4; ++i)
        {
            CreateMotion("BM_Attack/Attack_Far_Forward_0" + String(i), foward_motion_flags, 0, foward_allow_motion, -1, false);
        }

        // right
        int right_motion_flags = kMotion_XZR;
        int right_allow_motion = kMotion_XR;
        CreateMotion("BM_Attack/Attack_Close_Right", right_motion_flags, 0, right_allow_motion, -1, false);
        for (int i=1; i<=8; ++i)
        {
            CreateMotion("BM_Attack/Attack_Close_Right_0" + String(i), right_motion_flags, 0, right_allow_motion, -1, false);
        }
        CreateMotion("BM_Attack/Attack_Far_Right", right_motion_flags, 0, right_allow_motion, -1, false);
        // seems Attack_Far_Right_0 is not start at the origin
        CreateMotion("BM_Attack/Attack_Far_Right_01", right_motion_flags, kMotion_XZ, right_allow_motion, -1, false);
        for (int i=2; i<=4; ++i)
        {
            CreateMotion("BM_Attack/Attack_Far_Right_0" + String(i), right_motion_flags, 0, right_allow_motion, -1, false);
        }

        // back
        int back_motion_flags = kMotion_XZ;
        int back_allow_motion = kMotion_Z;
        CreateMotion("BM_Attack/Attack_Close_Back", back_motion_flags, 0, back_allow_motion, -1, false);
        for (int i=1; i<=8; ++i)
        {
            CreateMotion("BM_Attack/Attack_Close_Back_0" + String(i), back_motion_flags, 0, back_allow_motion, -1, false);
        }
        CreateMotion("BM_Attack/Attack_Far_Back", back_motion_flags, 0, back_allow_motion, -1, false);
        for (int i=1; i<=4; ++i)
        {
            CreateMotion("BM_Attack/Attack_Far_Back_0" + String(i), back_motion_flags, 0, back_allow_motion, -1, false);
        }

        // left
        int left_motion_flags = kMotion_XZR;
        int left_allow_motion = kMotion_XR;
        CreateMotion("BM_Attack/Attack_Close_Left", left_motion_flags, 0, left_allow_motion, -1, false);
        for (int i=1; i<=8; ++i)
        {
            CreateMotion("BM_Attack/Attack_Close_Left_0" + String(i), left_motion_flags, 0, left_allow_motion, -1, false);
        }
        CreateMotion("BM_Attack/Attack_Far_Left", left_motion_flags, 0, left_allow_motion, -1, false);
        for (int i=1; i<=4; ++i)
        {
            CreateMotion("BM_Attack/Attack_Far_Left_0" + String(i), left_motion_flags, 0, left_allow_motion, -1, false);
        }

        // Counters
        CreateMotion("BM_TG_Counter/Counter_Arm_Front_01", kMotion_XZ, kMotion_XZ, kMotion_XZR, -1, false);
        CreateMotion("TG_BM_Counter/Counter_Arm_Front_01", kMotion_XZ, kMotion_XZR, kMotion_XZR, -1, false);

        PostProcess();

        Print("Motion Process Time Cost = " + String(time.systemTime - startTime) + " ms");
    }

    void Stop()
    {
        motionNames.Clear();
        motions.Clear();
    }

    Motion@ CreateMotion(const String&in name, int motionFlag, int origninFlag, int allowMotion, int endFrame, bool loop, bool cutRotation = false, float speed = 1.0f)
    {
        // String dumpName("Attack_Close_Forward_03");
        Motion@ motion = FindMotion(name);
        if (motion !is null)
        {
            Print("motion " + name + " already exist!");
            return motion;
        }
        String animationName = "Animations/" + name + "_AnimStackTake 001.ani";
        Animation@ anim = cache.GetResource("Animation", animationName);
        if (anim is null) {
            return null;
        }

        @motion = Motion();
        motion.animationName = animationName;
        motion.animation = cache.GetResource("Animation", motion.animationName);
        // ProcessAnimation(motion.animationName, motionFlag, origninFlag, cutRotation, motion.motionKeys, name == dumpName);
        ProcessAnimation(motion.animationName, motionFlag, origninFlag, allowMotion, cutRotation, motion.motionKeys);
        if (endFrame < 0)
            endFrame = motion.motionKeys.length - 1;
        motion.endTime = float(endFrame) / FRAME_PER_SEC;
        motion.looped = loop;
        motion.speed = speed;
        Vector4 v = motion.motionKeys[0];
        motion.motionKeys[0] = Vector4(0, 0, 0, 0);
        motion.startFromOrigin = Vector3(v.x, v.y, v.z);
        motions.Push(motion);
        motionNames.Push(name);
        return motion;
    }
};


Animation@ FindAnimation(const String&in name)
{
   return cache.GetResource("Animation", GetAnimationName(name));
}

String GetAnimationName(const String&in name)
{
    return "Animations/" + name + "_AnimStackTake 001.ani";
}

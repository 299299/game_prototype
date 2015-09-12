
const int LAYER_MOVE = 0;
const int LAYER_ATTACK = 1;
const float FRAME_PER_SEC = 30.0f;

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
    Vector4                 startKey;

    Vector3                 startPosition;
    float                   startRotation;

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
        Vector4 ret = k1.Lerp(k2, t*FRAME_PER_SEC - float(i));
        return ret;
    }

    void Start(Node@ node, AnimationController@ ctrl, float localTime = 0.0f, float blendTime = 0.1)
    {
        PlayAnimation(ctrl, animationName, LAYER_MOVE, looped, blendTime, localTime, speed);
        startPosition = node.worldPosition;
        startRotation = node.worldRotation.eulerAngles.y;
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
            Vector3 tWorld = Quaternion(0, startRotation, 0) * Vector3(motionOut.x, motionOut.y, motionOut.z) + startPosition;
            MoveNode(node, tWorld, dt);
            // Print("key-yaw=" + String(motionOut.w) + " worldRotation=" + node.worldRotation.eulerAngles.ToString());
        }
        return localTime >= endTime;
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
        Vector4 tFinnal = GetKey(endTime);
        Vector3 tLocal(tFinnal.x, tFinnal.y, tFinnal.z);
        if (looped)
            debug.AddLine(node.worldRotation * tLocal + node.worldPosition, node.worldPosition, Color(0.5f, 0.5f, 0.7f), false);
        else
            debug.AddLine(Quaternion(0, startRotation, 0) * tLocal + startPosition,  startPosition, Color(0.5f, 0.5f, 0.7f), false);
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
        CreateMotion("Turn_Right_90", kMotion_R, 0, 16, false);
        CreateMotion("Turn_Right_180", kMotion_R, 0, 28, false);
        CreateMotion("Turn_Left_90", kMotion_R, 0, 22, false);
        CreateMotion("Walk_Forward", kMotion_Z, 0, -1, true);

        // Evades
        CreateMotion("Evade_Forward_01", kMotion_X | kMotion_Z, 0, -1, false);
        CreateMotion("Evade_Back_01", kMotion_X | kMotion_Z, 0, -1, false);

        // Attacks
        CreateMotion("Attack_Close_Left", kMotion_X | kMotion_Z | kMotion_R, 0, -1, false);
        CreateMotion("Attack_Close_Forward_08", kMotion_Z, 0, -1, false);
        CreateMotion("Attack_Close_Forward_08", kMotion_Z, 0, -1, false);

        // Counters
        CreateMotion("Counter_Arm_Front_01", kMotion_X | kMotion_Z, kMotion_X | kMotion_Z, -1, false);
        CreateMotion("Counter_Arm_Front_01_TG", kMotion_X | kMotion_Z, kMotion_X | kMotion_Z | kMotion_R, -1, false);

        PostProcess();

        Print("Motion Process Time Cost = " + String(time.systemTime - startTime) + " ms");
    }

    void Stop()
    {
        motionNames.Clear();
        motions.Clear();
    }

    Motion@ CreateMotion(const String&in name, int motionFlag, int origninFlag, int endFrame, bool loop, bool cutRotation = false, float speed = 1.0f)
    {
        Motion@ motion = Motion();
        motion.animationName = "Animation/" + name + "_AnimStackTake 001.ani";
        motion.animation = cache.GetResource("Animation", motion.animationName);
        ProcessAnimation(motion.animationName, motionFlag, origninFlag, cutRotation, motion.motionKeys);
        if (endFrame < 0)
            endFrame = motion.motionKeys.length - 1;
        motion.endTime = float(endFrame) / FRAME_PER_SEC;
        motion.looped = loop;
        motion.speed = speed;
        Vector4 v = motion.motionKeys[0];
        motion.motionKeys[0] = Vector4(0, 0, 0, 0);
        motion.startFromOrigin = Vector3(v.x, v.y, v.z);
        motion.startKey = v;
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
    return "Animation/" + name + "_AnimStackTake 001.ani";
}


const int LAYER_MOVE = 0;
const int LAYER_ATTACK = 1;

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

    float                   deltaRotation;
    Vector3                 deltaPosition;

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
        deltaRotation = 0;
        deltaPosition = Vector3(0, 0, 0);
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
            Vector3 tWorld = node.worldRotation * tLocal + node.worldPosition + deltaPosition;
            MoveNode(node, tWorld, dt);
        }
        else
        {
            Vector4 motionOut = GetKey(localTime);
            node.worldRotation = Quaternion(0, startRotation + motionOut.w + deltaRotation, 0);
            Vector3 tWorld = startRotationQua * Vector3(motionOut.x, motionOut.y, motionOut.z) + startPosition + deltaPosition;
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
        else {
            Vector4 tFinnal = GetKey(endTime);
            debug.AddLine(startRotationQua * Vector3(tFinnal.x, tFinnal.y, tFinnal.z) + startPosition,  startPosition, Color(0.5f, 0.5f, 0.7f), false);
            DebugDrawDirection(debug, node, startRotation + tFinnal.w, Color(0,1,0), 2.0);
        }
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

    MotionManager()
    {
        Print("MotionManager");
    }

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
        if (i < 0) {
            // Print("Can not find motion " + name);
            return null;
        }

        return motions[i];
    }

    void Start()
    {
        uint startTime = time.systemTime;

        PreProcess();

        //========================================================================
        // PLAYER MOTIONS
        //========================================================================
        // Locomotions
        CreateMotion("BM_Combat_Movement/Turn_Right_90", kMotion_XZR, 0, kMotion_R, 16, false);
        CreateMotion("BM_Combat_Movement/Turn_Right_180", kMotion_XZR, 0, kMotion_R, 28, false);
        CreateMotion("BM_Combat_Movement/Turn_Left_90", kMotion_XZR, 0, kMotion_R, 22, false);
        CreateMotion("BM_Combat_Movement/Walk_Forward", kMotion_XZR, 0, kMotion_Z, -1, true);

        CreateMotion("BM_Movement/Turn_Right_90", kMotion_R, 0, kMotion_R, 16, false);
        CreateMotion("BM_Movement/Turn_Right_180", kMotion_R, 0, kMotion_R, 25, false);
        CreateMotion("BM_Movement/Turn_Left_90", kMotion_R, 0, kMotion_R, 14, false);
        CreateMotion("BM_Movement/Walk_Forward", kMotion_Z, 0, kMotion_Z, -1, true);

        // Evades
        CreateMotion("BM_Combat/Evade_Forward_01", kMotion_XZR, 0, kMotion_ZR, -1, false);
        CreateMotion("BM_Combat/Evade_Right_01", kMotion_XZR, 0, kMotion_XR, -1, false, true);
        CreateMotion("BM_Combat/Evade_Back_01", kMotion_XZR, 0, kMotion_ZR, -1, false);
        CreateMotion("BM_Combat/Evade_Left_01", kMotion_XZR, 0, kMotion_XR, -1, false, true);

        CreateMotion("BM_Combat/Redirect", kMotion_XZR, 0, kMotion_XZR, 58, false);

        CreateMotion("BM_Combat_HitReaction/Hit_Reaction_SideLeft", kMotion_XZR, 0, kMotion_XZR, -1, false);

        // Attacks
        String preFix = "BM_Attack/";
        //========================================================================
        // FORWARD
        //========================================================================
        int foward_motion_flags = kMotion_XZR;
        int foward_allow_motion = kMotion_ZR;
        // weak forward
        CreateMotion(preFix + "Attack_Close_Weak_Forward", foward_motion_flags, 0, foward_allow_motion, -1, false);
        CreateMotion(preFix + "Attack_Close_Weak_Forward_01", foward_motion_flags, 0, foward_allow_motion, -1, false);
        CreateMotion(preFix + "Attack_Close_Weak_Forward_03", foward_motion_flags, 0, foward_allow_motion, -1, false);
        CreateMotion(preFix + "Attack_Close_Weak_Forward_04", foward_motion_flags, 0, foward_allow_motion, -1, false);
        CreateMotion(preFix + "Attack_Close_Weak_Forward_05", foward_motion_flags, 0, foward_allow_motion, -1, false);
        // close forward
        CreateMotion(preFix + "Attack_Close_Forward_04", foward_motion_flags, 0, foward_allow_motion, -1, false);
        CreateMotion(preFix + "Attack_Close_Forward_05", foward_motion_flags, 0, foward_allow_motion, -1, false);
        CreateMotion(preFix + "Attack_Close_Forward_06", foward_motion_flags, 0, foward_allow_motion, -1, false);
        CreateMotion(preFix + "Attack_Close_Run_Forward", foward_motion_flags, 0, foward_allow_motion, -1, false);
        // far forward
        CreateMotion(preFix + "Attack_Far_Forward_01", foward_motion_flags, 0, foward_allow_motion, -1, false);
        CreateMotion(preFix + "Attack_Far_Forward_02", foward_motion_flags, 0, foward_allow_motion, -1, false);
        CreateMotion(preFix + "Attack_Far_Forward_03", foward_motion_flags, 0, foward_allow_motion, -1, false);
        CreateMotion(preFix + "Attack_Far_Forward_04", foward_motion_flags, 0, foward_allow_motion, -1, false);
        CreateMotion(preFix + "Attack_Run_Far_Forward", foward_motion_flags, 0, foward_allow_motion, -1, false);

        //========================================================================
        // RIGHT
        //========================================================================
        int right_motion_flags = kMotion_XZR;
        int right_allow_motion = kMotion_XR;
        // weak right
        CreateMotion(preFix + "Attack_Close_Weak_Right_01", right_motion_flags, 0, right_allow_motion, -1, false);
        // close right
        CreateMotion(preFix + "Attack_Close_Right", right_motion_flags, 0, right_allow_motion, -1, false);
        CreateMotion(preFix + "Attack_Close_Right_01", right_motion_flags, 0, right_allow_motion, -1, false);
        CreateMotion(preFix + "Attack_Close_Right_03", right_motion_flags, 0, right_allow_motion, -1, false);
        CreateMotion(preFix + "Attack_Close_Right_05", right_motion_flags, 0, right_allow_motion, -1, false);
        CreateMotion(preFix + "Attack_Close_Right_08", right_motion_flags, 0, right_allow_motion, -1, false);
        // far right
        CreateMotion(preFix + "Attack_Far_Right", right_motion_flags, 0, right_allow_motion, -1, false);
        // seems Attack_Far_Right_0 is not start at the origin
        CreateMotion(preFix + "Attack_Far_Right_01", right_motion_flags, kMotion_XZ, right_allow_motion, -1, false);
        CreateMotion(preFix + "Attack_Far_Right_02", right_motion_flags, 0, right_allow_motion, -1, false);
        CreateMotion(preFix + "Attack_Far_Right_03", right_motion_flags, 0, right_allow_motion, -1, false);
        CreateMotion(preFix + "Attack_Far_Right_04", right_motion_flags, 0, right_allow_motion, -1, false);

        //========================================================================
        // BACK
        //========================================================================
        int back_motion_flags = kMotion_XZR;
        int back_allow_motion = kMotion_ZR;
        // weak back
        CreateMotion(preFix + "Attack_Close_Weak_Back", back_motion_flags, 0, back_allow_motion, -1, false);
        CreateMotion(preFix + "Attack_Close_Weak_Back_01", back_motion_flags, 0, back_allow_motion, -1, false);
        // close back
        CreateMotion(preFix + "Attack_Close_Back", back_motion_flags, 0, back_allow_motion, -1, false);
        CreateMotion(preFix + "Attack_Close_Back_01", back_motion_flags, 0, back_allow_motion, -1, false);
        CreateMotion(preFix + "Attack_Close_Back_02", back_motion_flags, 0, back_allow_motion, -1, false);
        CreateMotion(preFix + "Attack_Close_Back_03", back_motion_flags, 0, back_allow_motion, -1, false);
        CreateMotion(preFix + "Attack_Close_Back_05", back_motion_flags, 0, back_allow_motion, -1, false);
        CreateMotion(preFix + "Attack_Close_Back_06", back_motion_flags, 0, back_allow_motion, -1, false);
        CreateMotion(preFix + "Attack_Close_Back_07", back_motion_flags, 0, back_allow_motion, -1, false);
        CreateMotion(preFix + "Attack_Close_Back_08", back_motion_flags, 0, back_allow_motion, -1, false);
        // far back
        CreateMotion(preFix + "Attack_Far_Back_02", back_motion_flags, 0, back_allow_motion, -1, false);

        //========================================================================
        // LEFT
        //========================================================================
        int left_motion_flags = kMotion_XZR;
        int left_allow_motion = kMotion_XR;
        // weak left
        CreateMotion(preFix + "Attack_Close_Weak_Left", left_motion_flags, 0, left_allow_motion, -1, false);
        CreateMotion(preFix + "Attack_Close_Weak_Left_02", left_motion_flags, 0, left_allow_motion, -1, false);

        // close left
        CreateMotion(preFix + "Attack_Close_Left_02", left_motion_flags, 0, left_allow_motion, -1, false);
        CreateMotion(preFix + "Attack_Close_Left_05", left_motion_flags, 0, left_allow_motion, -1, false);
        CreateMotion(preFix + "Attack_Close_Left_08", left_motion_flags, 0, left_allow_motion, -1, false);
        // far left
        CreateMotion(preFix + "Attack_Far_Left", left_motion_flags, 0, left_allow_motion, -1, false);
        CreateMotion(preFix + "Attack_Far_Left_02", left_motion_flags, 0, left_allow_motion, -1, false);
        CreateMotion(preFix + "Attack_Far_Left_03", left_motion_flags, 0, left_allow_motion, -1, false);

        // Counters
        String counter_prefix = "BM_TG_Counter/";
        CreateMotion(counter_prefix + "Counter_Arm_Back_01", kMotion_XZR, kMotion_XZR, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Arm_Back_03", kMotion_XZR, kMotion_XZR, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Arm_Back_05", kMotion_XZR, kMotion_XZR, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Arm_Back_06", kMotion_XZR, kMotion_XZR, kMotion_XZR, -1, false);

        CreateMotion(counter_prefix + "Counter_Arm_Back_Weak_01", kMotion_XZR, kMotion_XZR, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Arm_Back_Weak_02", kMotion_XZR, kMotion_XZR, kMotion_XZR, -1, false);

        CreateMotion(counter_prefix + "Counter_Arm_Front_02", kMotion_XZR, kMotion_XZ, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Arm_Front_03", kMotion_XZR, kMotion_XZ, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Arm_Front_04", kMotion_XZR, kMotion_XZ, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Arm_Front_05", kMotion_XZR, kMotion_XZ, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Arm_Front_06", kMotion_XZR, kMotion_XZ, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Arm_Front_07", kMotion_XZR, kMotion_XZ, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Arm_Front_08", kMotion_XZR, kMotion_XZ, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Arm_Front_09", kMotion_XZR, kMotion_XZ, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Arm_Front_10", kMotion_XZR, kMotion_XZ, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Arm_Front_13", kMotion_XZR, kMotion_XZ, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Arm_Front_14", kMotion_XZR, kMotion_XZ, kMotion_XZR, -1, false);

        CreateMotion(counter_prefix + "Counter_Arm_Front_Weak_02", kMotion_XZR, kMotion_XZ, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Arm_Front_Weak_04", kMotion_XZR, kMotion_XZ, kMotion_XZR, -1, false);

        CreateMotion(counter_prefix + "Counter_Leg_Back_01", kMotion_XZR, kMotion_XZR, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Leg_Back_02", kMotion_XZR, kMotion_XZR, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Leg_Back_05", kMotion_XZR, kMotion_XZR, kMotion_XZR, -1, false);

        CreateMotion(counter_prefix + "Counter_Leg_Back_Weak_01", kMotion_XZR, kMotion_XZR, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Leg_Back_Weak_03", kMotion_XZR, kMotion_XZR, kMotion_XZR, -1, false);

        CreateMotion(counter_prefix + "Counter_Leg_Front_01", kMotion_XZR, kMotion_XZR, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Leg_Front_02", kMotion_XZR, kMotion_XZR, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Leg_Front_03", kMotion_XZR, kMotion_XZ, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Leg_Front_04", kMotion_XZR, kMotion_XZR, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Leg_Front_06", kMotion_XZR, kMotion_XZ, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Leg_Front_07", kMotion_XZR, kMotion_XZR, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Leg_Front_08", kMotion_XZR, kMotion_XZR, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Leg_Front_09", kMotion_XZR, kMotion_XZR, kMotion_XZR, -1, false);

        //========================================================================
        // THUG MOTIONS
        //========================================================================
        preFix = "TG_Combat/";
        CreateMotion(preFix + "Step_Forward", kMotion_Z, 0, kMotion_XZR, -1, false);
        CreateMotion(preFix + "Step_Right", kMotion_X, 0, kMotion_XZR, -1, false);
        CreateMotion(preFix + "Step_Back", kMotion_Z, 0, kMotion_XZR, -1, false);
        CreateMotion(preFix + "Step_Left", kMotion_X, 0, kMotion_XZR, -1, false);
        CreateMotion(preFix + "Step_Forward_Long", kMotion_Z, 0, kMotion_XZR, -1, false);
        CreateMotion(preFix + "Step_Right_Long", kMotion_X, 0, kMotion_XZR, -1, false);
        CreateMotion(preFix + "Step_Back_Long", kMotion_Z, 0, kMotion_XZR, -1, false);
        CreateMotion(preFix + "Step_Left_Long", kMotion_X, 0, kMotion_XZR, -1, false);

        CreateMotion(preFix + "135_Turn_Left", kMotion_XZR, 0, kMotion_R, 32, false);
        CreateMotion(preFix + "135_Turn_Right", kMotion_XZR, 0, kMotion_R, 32, false);

        CreateMotion(preFix + "Run_Forward_Combat", kMotion_Z, 0, kMotion_XZR, -1, true);
        CreateMotion(preFix + "Redirect_push_back", kMotion_XZR, kMotion_XZR, kMotion_XZR, -1, false);
        CreateMotion(preFix + "Redirect_Stumble_JK", kMotion_XZR, kMotion_XZR, kMotion_XZR, -1, false);

        CreateMotion(preFix + "Attack_Kick", kMotion_XZR, 0, kMotion_XZR, -1, true);
        CreateMotion(preFix + "Attack_Kick_01", kMotion_XZR, 0, kMotion_XZR, -1, true);
        CreateMotion(preFix + "Attack_Kick_02", kMotion_XZR, 0, kMotion_XZR, -1, true);
        CreateMotion(preFix + "Attack_Punch", kMotion_XZR, 0, kMotion_XZR, -1, true);
        CreateMotion(preFix + "Attack_Punch_01", kMotion_XZR, 0, kMotion_XZR, -1, true);
        CreateMotion(preFix + "Attack_Punch_02", kMotion_XZR, 0, kMotion_XZR, -1, true);


        String preFix1 = "TG_HitReaction/";
        CreateMotion(preFix1 + "HitReaction_Left", kMotion_XZR, 0, kMotion_XZR, -1, false);
        CreateMotion(preFix1 + "HitReaction_Right", kMotion_XZR, 0, kMotion_XZR, -1, false);
        CreateMotion(preFix1 + "HitReaction_Back_NoTurn", kMotion_XZR, 0, kMotion_XZR, -1, false);
        CreateMotion(preFix1 + "Generic_Hit_Reaction", kMotion_XZR, 0, kMotion_XZR, -1, false);

        CreateMotion(preFix1 + "Push_Reaction", kMotion_XZR, 0, kMotion_XZR, -1, false);
        CreateMotion(preFix1 + "Push_Reaction_From_Back", kMotion_XZR, 0, kMotion_XZR, -1, false);

        counter_prefix = "TG_BM_Counter/";
        CreateMotion(counter_prefix + "Counter_Arm_Back_01", kMotion_XZR, kMotion_XZ, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Arm_Back_03", kMotion_XZR, kMotion_XZ, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Arm_Back_05", kMotion_XZR, kMotion_XZ, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Arm_Back_06", kMotion_XZR, kMotion_XZ, kMotion_XZR, -1, false);

        CreateMotion(counter_prefix + "Counter_Arm_Back_Weak_01", kMotion_XZR, kMotion_XZ, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Arm_Back_Weak_02", kMotion_XZR, kMotion_XZ, kMotion_XZR, -1, false);

        CreateMotion(counter_prefix + "Counter_Arm_Front_02", kMotion_XZR, kMotion_XZR, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Arm_Front_03", kMotion_XZR, kMotion_XZR, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Arm_Front_04", kMotion_XZR, kMotion_XZR, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Arm_Front_05", kMotion_XZR, kMotion_XZR, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Arm_Front_06", kMotion_XZR, kMotion_XZR, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Arm_Front_07", kMotion_XZR, kMotion_XZR, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Arm_Front_08", kMotion_XZR, kMotion_XZR, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Arm_Front_09", kMotion_XZR, kMotion_XZR, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Arm_Front_10", kMotion_XZR, kMotion_XZR, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Arm_Front_13", kMotion_XZR, kMotion_XZR, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Arm_Front_14", kMotion_XZR, kMotion_XZR, kMotion_XZR, -1, false);

        CreateMotion(counter_prefix + "Counter_Arm_Front_Weak_02", kMotion_XZR, kMotion_XZR, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Arm_Front_Weak_04", kMotion_XZR, kMotion_XZR, kMotion_XZR, -1, false);

        CreateMotion(counter_prefix + "Counter_Leg_Back_01", kMotion_XZR, kMotion_XZ, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Leg_Back_02", kMotion_XZR, kMotion_XZ, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Leg_Back_05", kMotion_XZR, kMotion_XZ, kMotion_XZR, -1, false);

        CreateMotion(counter_prefix + "Counter_Leg_Back_Weak_01", kMotion_XZR, kMotion_XZ, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Leg_Back_Weak_03", kMotion_XZR, kMotion_XZ, kMotion_XZR, -1, false);

        CreateMotion(counter_prefix + "Counter_Leg_Front_01", kMotion_XZR, kMotion_XZ, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Leg_Front_02", kMotion_XZR, kMotion_XZ, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Leg_Front_03", kMotion_XZR, kMotion_XZR, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Leg_Front_04", kMotion_XZR, kMotion_XZ, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Leg_Front_06", kMotion_XZR, kMotion_XZR, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Leg_Front_07", kMotion_XZR, kMotion_XZ, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Leg_Front_08", kMotion_XZR, kMotion_XZ, kMotion_XZR, -1, false);
        CreateMotion(counter_prefix + "Counter_Leg_Front_09", kMotion_XZR, kMotion_XZ, kMotion_XZR, -1, false);

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
        //String dumpName("BM_Combat/Evade_Left_01");
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
        //ProcessAnimation(motion.animationName, motionFlag, origninFlag, allowMotion, cutRotation, motion.motionKeys, name == dumpName);
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
        Vector4 endKey = motion.GetKey(motion.endTime);
        Print("Motion " + name + " endKey=" + endKey.ToString());
        return motion;
    }
};


MotionManager@ gMotionMgr = MotionManager();

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
    String                  name;
    Animation@              animation;
    Array<Vector4>          motionKeys;
    Vector3                 startPosition;
    Quaternion              startRotation;
    float                   targetYaw;
    float                   startYaw;
    int                     endFrame;
    float                   endTime;
    float                   fixYawPerSec;
    bool                    looped;
    bool                    fixYaw;
    float                   speed;
    int                     status;
    Vector3                 startFromOrigin;

    Motion(const String&in animName, float _targetYaw, int _endFrame, bool _loop, bool _fixYaw, float _speed = 1.0f)
    {
        Print("Motion(" + animName + "," + String(_targetYaw) + "," + String(_endFrame) + ")");
        Load(animName, _targetYaw, _fixYaw, _endFrame);
        targetYaw = _targetYaw;
        if (_endFrame < 0 && !_loop)
            _endFrame = motionKeys.length - 1;
        endFrame = _endFrame;
        endTime = float(endFrame) / 30.0f;
        if (endTime < 0)
            endTime = animation.length;
        looped = _loop;
        name = animName;
        fixYawPerSec = 0.0f;
        fixYaw = _fixYaw;
        speed = _speed;
        status = 0;
        if (fixYaw)
        {
            float endYaw = motionKeys[endFrame].w;
            fixYawPerSec = (targetYaw - endYaw) / endTime;
            Print("endTime=" + String(endTime) + " fixYawPerSec=" + String(fixYawPerSec) + " targetYaw=" + String(targetYaw));
        }
    }

    ~Motion()
    {
        @animation = null;
    }

    void Load(const String&in anim, float _targetYaw, bool _fixYaw, int _endFrame)
    {
        animation = cache.GetResource("Animation", anim);
        String motion_file = "Data/" + GetPath(anim) + GetFileName(anim) + "_motion.xml";

        File@ file = File();
        if (file.Open(motion_file))
        {
            XMLFile@ xml = XMLFile();
            if (xml.Load(file))
            {
                XMLElement root = xml.GetRoot();
                XMLElement child1 = root.GetChild("motion_keys");
                XMLElement child2 = root.GetChild("property");
                startFromOrigin = child2.GetVector3("startFromOrigin");

                Print("motion: " + anim + " startFromOrigin=" + startFromOrigin.ToString());

                XMLElement child = child1.GetChild();
                int i = 0;

                while (!child.isNull)
                {
                    float t = child.GetFloat("time");
                    Vector3 translation = child.GetVector3("translation");
                    float rotation = child.GetFloat("rotation");
                    // Print("frame:" + String(i) + " time: " + String(t) + " translation: " + translation.ToString() + " rotation: " + String(rotation));
                    Vector4 v(translation.x, translation.y, translation.z, rotation);
                    motionKeys.Push(v);
                    child = child.GetNext();
                    ++i;
                }
            }
        }

        if (motionKeys.empty)
            Print("Error " + anim + " no motion " + motion_file + "!");
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

        uint i = uint(t * 30.0f);
        if (i >= motionKeys.length)
            i = motionKeys.length - 1;
        Vector4 k1 = motionKeys[i];
        uint next_i = i + 1;
        if (next_i >= motionKeys.length)
            next_i = motionKeys.length - 1;
        Vector4 k2 = motionKeys[next_i];
        Vector4 ret = k1.Lerp(k2, t*30 - float(i));
        return ret;
    }

    void Start(Node@ node, AnimationController@ ctrl, float localTime = 0.0f, float blendTime = 0.1)
    {
        status = 0;
        startPosition = node.worldPosition;
        startRotation = node.worldRotation;
        startYaw = startRotation.eulerAngles.y;
        PlayAnimation(ctrl, name, LAYER_MOVE, looped, blendTime, localTime, speed);
        Print("name=" + name + " startPosition=" + startPosition.ToString() + " startYaw=" + String(startYaw) + " localTime=" + String(localTime));
    }

    bool Move(float dt, Node@ node, AnimationController@ ctrl)
    {
        float localTime = ctrl.GetTime(name);
        if (looped)
        {
            Vector4 motionOut = Vector4(0, 0, 0, 0);
            GetMotion(localTime, dt, looped, motionOut);
            if (status == 0)
                node.Yaw(motionOut.w);
            Vector3 tLocal(motionOut.x, motionOut.y, motionOut.z);
            tLocal = tLocal * ctrl.GetWeight(name);
            Vector3 tWorld = node.worldRotation * tLocal + node.worldPosition;
            // Print("name=" + name + " translate=" + (tWorld - startPosition).ToString() + " yaw=" + String(motionOut.w) + " t=" + String(localTime));
            MoveNode(node, tWorld, dt);
        }
        else
        {
            if (localTime >= endTime)
            {
                if (fixYaw && status == 0)
                {
                    float finnalYaw = node.worldRotation.eulerAngles.y;
                    float yaw = targetYaw + startYaw - finnalYaw;
                    node.Yaw(yaw);
                    Print("FINISHED FINAL-YAW = " + String(finnalYaw) + " YAW=" + String(yaw));
                }
                status = 1;
            }

            Vector4 motionOut = Vector4(0, 0, 0, 0);
            motionOut = GetKey(localTime);
            Vector3 tLocal(motionOut.x, motionOut.y, motionOut.z);
            tLocal = tLocal * ctrl.GetWeight(name);
            float yaw = motionOut.w + fixYawPerSec * localTime + startYaw;
            node.worldRotation = Quaternion(0, yaw, 0);
            Vector3 tWorld = startRotation * tLocal + startPosition;
            // Print("name=" + name + " translate=" + (tWorld - startPosition).ToString() + " yaw=" + String(yaw) + " t=" + String(localTime) + " frame=" + String(int(localTime*30.0f)));
            MoveNode(node, tWorld, dt);
        }

        return status == 1;
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
        Vector4 finnalPos = GetKey(endTime);
        Vector3 tLocal(finnalPos.x, finnalPos.y, finnalPos.z);
        debug.AddLine(startRotation * tLocal + startPosition, node.worldPosition, Color(0.5f, 0.5f, 0.7f), false);
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
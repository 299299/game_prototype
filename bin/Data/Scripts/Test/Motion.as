
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
    String                  name;
    Animation@              animation;
    Array<Vector4>          motionKeys;
    float                   endTime;
    bool                    looped;
    float                   speed;
    Vector3                 startFromOrigin;

    Motion(const String&in animName, int _endFrame, bool _loop, float _speed = 1.0f)
    {
        Print("Motion(" + animName + "," + String(_endFrame) + "," + String(_loop) + "," + String(_speed) + ")");
        Load(animName);
        if (_endFrame < 0)
            _endFrame = motionKeys.length - 1;
        endTime = float(_endFrame) / FRAME_PER_SEC;
        looped = _loop;
        name = animName;
        speed = _speed;
    }

    ~Motion()
    {
        @animation = null;
    }

    void Load(const String&in anim)
    {
        animation = cache.GetResource("Animation", anim);
        File@ file = File();
        String motionFile = "Data/" + GetPath(anim) + GetFileName(anim) + "_motion.xml";
        if (file.Open(motionFile))
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
            Print("Error " + anim + " no motion " + motionFile + "!");
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
        PlayAnimation(ctrl, name, LAYER_MOVE, looped, blendTime, localTime, speed);
    }

    bool Move(float dt, Node@ node, AnimationController@ ctrl)
    {
        float localTime = ctrl.GetTime(name);
        Vector4 motionOut = Vector4(0, 0, 0, 0);
        GetMotion(localTime, dt, looped, motionOut);
        node.Yaw(motionOut.w);
        Vector3 tLocal(motionOut.x, motionOut.y, motionOut.z);
        tLocal = tLocal * ctrl.GetWeight(name);
        Vector3 tWorld = node.worldRotation * tLocal + node.worldPosition;
        MoveNode(node, tWorld, dt);
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
        Vector4 finnalPos = GetKey(endTime);
        Vector3 tLocal(finnalPos.x, finnalPos.y, finnalPos.z);
        debug.AddLine(node.worldRotation * tLocal + node.worldPosition, node.worldPosition, Color(0.5f, 0.5f, 0.7f), false);
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
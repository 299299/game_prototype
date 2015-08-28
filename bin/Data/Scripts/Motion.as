


class Motion
{
    Motion(String animName, float targetYaw, int endFrame, bool loop, bool fixYaw)
    {
        Load(animName);
        target_yaw = targetYaw;
        if (endFrame < 0 && !loop)
        {
            endFrame = motion_keys.length - 1;
        }
        end_frame = endFrame;
        end_time = float(end_frame) / 30.0f;
        looped = loop;
        name = animName;
        fix_yaw_per_second = 0.0f;
        fix_yaw = fixYaw;
        if (fixYaw)
        {
            float end_yaw = motion_keys[endFrame].w;
            fix_yaw_per_second = (target_yaw - end_yaw) / end_time;
            Print("end_time=" + String(end_time) + " frame end yaw=" + String(end_yaw) + " target yaw=" + String(target_yaw) + " fix_yaw_per_second=" + String(fix_yaw_per_second));
        }
    }

    void Load(String anim)
    {
        animation = cache.GetResource("Animation", anim);
        String motion_file = "Data/" + GetPath(anim) + GetFileName(anim) + "_motion.xml";

        File@ file = File();
        if (file.Open(motion_file))
        {
            XMLFile@ xml = XMLFile();
            if (xml.Load(file))
            {
                Print(anim + " has motion " + motion_file + "!");

                XMLElement root = xml.GetRoot("motion_keys");
                XMLElement child = root.GetChild();
                int i = 0;

                while (!child.isNull)
                {
                    float t = child.GetFloat("time");
                    Vector3 translation = child.GetVector3("translation");
                    float rotation = child.GetFloat("rotation");
                    Print("frame:" + String(i++) + " time: " + String(t) + " translation: " + translation.ToString() + " rotation: " + String(rotation));
                    motion_times.Push(t);
                    Vector4 v(translation.x, translation.y, translation.z, rotation);
                    motion_keys.Push(v);
                    child = child.GetNext();
                }
            }
        }
    }

    void GetMotion(float t, float dt, bool loop, Vector4& out out_motion)
    {
        if (motion_times.empty)
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
        uint i = uint(t * 30.0f);
        Vector4 k1 = motion_keys[i];
        uint next_i = i + 1;
        if (next_i >= motion_keys.length)
            next_i = motion_keys.length - 1;
        Vector4 k2 = motion_keys[next_i];
        Vector4 ret = k1.Lerp(k2, t*30 - float(i));
        return ret;
    }

    void Start(Node@ node)
    {
        start_position = node.worldPosition;
        start_rotation = node.worldRotation;
        start_yaw = start_rotation.eulerAngles.y;

        AnimationController@ ctrl = node.GetComponent("AnimationController");
        ctrl.Play(name, 0, looped);
        ctrl.SetTime(name, 0);
        ctrl.SetSpeed(name, 1);

        Print("start_position=" + start_position.ToString() + " start_rotation=" + String(start_yaw));
    }

    bool Move(float dt, Node@ node)
    {
        AnimationController@ ctrl = node.GetComponent("AnimationController");
        float local_time = ctrl.GetTime(name);
        if (looped)
        {
            Vector4 motion_out = Vector4(0, 0, 0, 0);
            GetMotion(local_time, dt, looped, motion_out);
            node->Yaw(motion_out.w);
            Vector3 t_local(motion_out.x, motion_out.y, motion_out.z);
            Vector3 t_world = node.worldRotation * t_local + node.worldPosition;
            MoveNode(node, t_world, dt);
        }
        else
        {
            if (local_time >= end_time)
            {
                if (fix_yaw && ctrl.GetSpeed(name) > 0)
                {
                    float final_yaw = node.worldRotation.eulerAngles.y;
                    node.Yaw(target_yaw + start_yaw - final_yaw);
                    ctrl.SetSpeed(name, 0);
                    Print("FINISHED FINAL YAW = " + String(final_yaw));
                }
                return true;
            }

            Vector4 motion_out = Vector4(0, 0, 0, 0);
            motion_out = motion.GetKey(local_time);
            Vector3 t_local(motion_out.x, motion_out.y, motion_out.z);
            float yaw = motion_out.w + fix_yaw_per_second * local_time + start_yaw;
            node.worldRotation = Quaternion(0, yaw, 0);
            MoveNode(start_rotation * t_local + start_position);
            Print("motion=" + motion_out.ToString() + " yaw=" + String(yaw) + " t=" + String(local_time));
        }
        return false;
    }

    void MoveNode(Node@ node, const Vector3& t_world, float dt)
    {
        RigidBody@ body = node.GetComponent("RigidBody");
        if (body is null)
        {
            node.worldPosition = t_world;
        }
        else
        {
            body.linearVelocity = (t_world - node.worldPosition) / dt;
        }
    }

    void DebugDraw(DebugRenderer@ debug, Node@ node)
    {
        AnimationController@ ctrl = node.GetComponent("AnimationController");
        Vector4 finnal_pos = GetKey(ctrl.GetLength(name));
        Vector3 t_local(finnal_pos.x, finnal_pos.y, finnal_pos.z);
        debug.AddLine(start_rotation * t_local + start_position, node.worldPosition, Color(0.5f, 0.5f, 0.7f), false);
    }

    String                  name;
    Animation@              animation;
    Array<float>            motion_times;
    Array<Vector4>          motion_keys;
    Vector3                 start_position;
    Quaternion              start_rotation;
    float                   target_yaw;
    float                   start_yaw;
    int                     end_frame;
    float                   end_time;
    float                   fix_yaw_per_second;
    bool                    looped;
    bool                    fix_yaw;
};
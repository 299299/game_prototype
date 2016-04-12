//
//
//  128 --> 3.25
//  256 --> 6.5
//  384 --> 9.75
//
//

enum LineType
{
    LINE_COVER,
    LINE_RAILING,
    LINE_EDGE,
    LINE_TYPE_NUM
};

enum LineFlags
{
    LINE_THIN_WALL  = (1 << 0),
    LINE_SHORT_WALL = (1 << 1),
};

enum LineAction
{
    LINE_ACTION_NULL,
    LINE_ACTION_CLIMB_OVER,
    LINE_ACTION_CLIMB_UP,
    LINE_ACTION_HANG,
    LINE_ACTION_DANGE,
    LINE_ACTION_CLIMB_DOWN,
    LINE_ACTION_FALL_DOWN,
};

const float LINE_MIN_LENGTH = 2.0f;
const float LINE_MAX_HEIGHT_DIFF = 15;

class Line
{
    Ray             ray;
    Vector3         end;
    Vector3         invDir;
    Vector3         size;

    float           length;
    float           lengthSquared;
    int             type;
    float           angle;
    float           maxFacingDiff = 45;

    uint            nodeId;
    int             flags;

    bool HasFlag(int flag)
    {
        return flags & flag != 0;
    }

    Vector3 Project(const Vector3& charPos)
    {
        return ray.Project(charPos);
    }

    bool IsProjectPositionInLine(const Vector3& proj, float bound = 0.5f)
    {
        float l_to_start = (proj - ray.origin).length;
        float l_to_end = (proj - end).length;
        // check if project is in line
        if (l_to_start > length || l_to_end > length)
            return false;
        // check if project is in bound
        return l_to_start >= bound && l_to_end >= bound;
    }

    Vector3 FixProjectPosition(const Vector3& proj, float bound = 0.5f)
    {
        float l_to_start = (proj - ray.origin).length;
        float l_to_end = (proj - end).length;
        bool bFix = false;
        if (l_to_start > length || l_to_end > length)
            bFix = true;
        if (l_to_start < bound || l_to_end < bound)
            bFix = true;
        if (!bFix)
            return proj;
        // Print("FixProjectPosition");
        if (l_to_start > l_to_end)
            return end + invDir * bound;
        else
            return ray.origin + ray.direction * bound;
    }

    int GetHead(const Quaternion& rot)
    {
        float yaw = rot.eulerAngles.y;
        float diff = AngleDiff(angle - AngleDiff(yaw));
        // Print("yaw=" + yaw + " angle=" + angle + " diff=" + diff);
        if (Abs(diff) > 90)
            return 1;
        return 0;
    }

    float GetHeadDirection(const Quaternion& rot)
    {
        int head = GetHead(rot);
        Vector3 dir;
        if (head == 1)
            dir = ray.origin - end;
        else
            dir = end - ray.origin;
        return Atan2(dir.x, dir.z);
    }

    int GetTowardHead(float towardAngle)
    {
        float angleDiff = Abs(AngleDiff(angle - towardAngle));
        if (angleDiff > 90)
            return 0;
        return 1;
    }

    float Test(const Vector3& pos, float angle)
    {
        if (Abs(pos.y - end.y) > LINE_MAX_HEIGHT_DIFF)
            return -1;

        Vector3 project = ray.Project(pos);
        if (!IsProjectPositionInLine(project))
            return -1;

        project.y = pos.y;
        Vector3 dir = project - pos;
        float projDir = Atan2(dir.x, dir.z);
        float aDiff = AngleDiff(projDir - angle);
        if (Abs(aDiff) > maxFacingDiff)
            return -1;

        return dir.length;
    }

    void DebugDraw(DebugRenderer@ debug, const Color&in color)
    {
        //debug.AddCross(ray.origin, 0.25f, RED, false);
        //debug.AddCross(end, 0.25f, BLUE, false);
        debug.AddSphere(Sphere(ray.origin, 0.15f), YELLOW, false);
        debug.AddSphere(Sphere(end, 0.15f), YELLOW, false);
        debug.AddLine(ray.origin, end, color, false);
    }

    float GetProjectFacingDir(const Vector3& pos, float angle)
    {
        Vector3 proj = Project(pos);
        proj.y = pos.y;
        Vector3 dir = proj - pos;
        float projDir = Atan2(dir.x, dir.z);
        float aDiff = AngleDiff(projDir - angle);
        return Abs(aDiff);
    }

    Vector3 GetNearPoint(const Vector3& pos)
    {
        float start_sqr = (pos - ray.origin).lengthSquared;
        float end_sqr = (pos - end).lengthSquared;
        return (start_sqr < end_sqr) ? ray.origin : end;
    }

    Vector3 GetCenter()
    {
        return ray.direction * length / 2 + ray.origin;
    }

    Vector3 GetLinePoint(Vector3 dir)
    {
        int towardHead = GetTowardHead(Atan2(dir.x, dir.z));
        return (towardHead == 0) ? ray.origin : end;
    }

    bool TestAngleDiff(Line@ l, float diff, float maxError = 5)
    {
        float angle_diff = Abs(AngleDiff(l.angle - this.angle));
        return Abs(angle_diff - diff) < maxError;
    }
};

bool GetNodeSizeAndOffset(Node@ n, Vector3&out size, Vector3&out offset)
{
    CollisionShape@ shape = n.GetComponent("CollisionShape");
    if (shape !is null)
    {
        size = shape.size;
        offset = shape.position;
        return true;
    }

    StaticModel@ staticModel = n.GetComponent("StaticModel");
    if (staticModel !is null)
    {
        size = staticModel.boundingBox.size;
        offset = Vector3(0, 0, 0);
        return true;
    }

    AnimatedModel@ animateModel = n.GetComponent("AnimatedModel");
    if (animateModel !is null)
    {
        size = animateModel.boundingBox.size;
        offset = Vector3(0, 0, 0);
        return true;
    }

    return false;
}

bool GetCorners(Node@ n, Vector3&out outSize, Vector3&out p1, Vector3&out p2, Vector3&out p3, Vector3&out p4)
{
    Vector3 size, offset;
    if (!GetNodeSizeAndOffset(n, size, offset))
        return false;

    Vector3 halfSize = size/2;
    p1 = Vector3(halfSize.x, halfSize.y, halfSize.z);
    p2 = Vector3(halfSize.x, halfSize.y, -halfSize.z);
    p3 = Vector3(-halfSize.x, halfSize.y, -halfSize.z);
    p4 = Vector3(-halfSize.x, halfSize.y, halfSize.z);
    p1 = n.LocalToWorld(p1 + offset);
    p2 = n.LocalToWorld(p2 + offset);
    p3 = n.LocalToWorld(p3 + offset);
    p4 = n.LocalToWorld(p4 + offset);

    outSize = size * n.worldScale;

    Print(n.name + " size=" + outSize.ToString());

    return true;
}

bool GetCorners(Node@ n, Vector3&out outSize, Vector3&out p1, Vector3&out p2)
{
    Vector3 size, offset;
    if (!GetNodeSizeAndOffset(n, size, offset))
        return false;

    Vector3 halfSize = size/2;
    float x = halfSize.x * n.worldScale.x;
    float z = halfSize.z * n.worldScale.z;

    if (x > z)
    {
        p1 = Vector3(halfSize.x, halfSize.y, 0);
        p2 = Vector3(-halfSize.x, halfSize.y, 0);
    }
    else
    {
        p1 = Vector3(0, halfSize.y, halfSize.z);
        p2 = Vector3(0, halfSize.y, -halfSize.z);
    }

    p1 = n.LocalToWorld(p1 + offset);
    p2 = n.LocalToWorld(p2 + offset);

    outSize = size * n.worldScale;

    Print(n.name + " size=" + outSize.ToString());

    return true;
}

class LineWorld
{
    Array<Line@>            lines;
    Array<Color>            debugColors;
    Array<Line@>            cacheLines;
    //Array<float>            cacheError;

    LineWorld()
    {
        debugColors.Resize(LINE_TYPE_NUM);
        debugColors[LINE_RAILING] = Color(0.25f, 0.25f, 0.75f);
        debugColors[LINE_COVER] = Color(0.75f, 0.15f, 0.15f);
        debugColors[LINE_EDGE] = Color(0.25f, 0.5f, 0.75f);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        for (uint i=0; i<lines.length; ++i)
        {
            Line@ l = lines[i];
            l.DebugDraw(debug, debugColors[l.type]);
        }
    }

    void AddLine(Line@ l)
    {
        lines.Push(l);
    }

    Line@ CreateLine(int type, const Vector3&in start, const Vector3&in end, const Vector3&in size, Node@ node)
    {
        Vector3 dir = end - start;
        float lenSQR = dir.lengthSquared;
        if (lenSQR < LINE_MIN_LENGTH*LINE_MIN_LENGTH)
            return null;

        Line@ l = Line();
        l.ray.origin = start;
        l.end = end;
        l.type = type;
        l.ray.direction = dir.Normalized();
        l.invDir = (start - end).Normalized();
        l.length = dir.length;
        l.lengthSquared = lenSQR;
        l.angle = Atan2(dir.x, dir.z);
        l.nodeId = node.id;
        l.size = size;

        if (size.x < LINE_MIN_LENGTH || size.z < LINE_MIN_LENGTH)
            l.flags |= LINE_THIN_WALL;
        if (size.y < 1.0f)
            l.flags |= LINE_SHORT_WALL;

        AddLine(l);
        Print("CreateLine type=" + type + " for node=" + node.name + " size=" + size.ToString() + " flags=" + l.flags);
        return l;
    }

    void CreateLine(int type, Node@ n)
    {
        Vector3 size, p1, p2, p3, p4;
        if (type == LINE_EDGE)
        {
            if (!GetCorners(n, size, p1, p2, p3, p4))
                return;

            if (size.x < LINE_MIN_LENGTH || size.z < LINE_MIN_LENGTH)
            {
                // if line length is too short just merge them to one
                if (!GetCorners(n, size, p1, p2))
                    return;
                CreateLine(type, p1, p2, size, n);
            }
            else
            {
                CreateLine(type, p1, p2, size, n);
                CreateLine(type, p2, p3, size, n);
                CreateLine(type, p3, p4, size, n);
                CreateLine(type, p4, p1, size, n);
            }
        }
        else
        {
            if (!GetCorners(n, size, p1, p2))
                return;
            CreateLine(type, p1, p2, size, n);
        }
    }

    void Process(Scene@ scene)
    {
        for (uint i=0; i<scene.numChildren; ++i)
        {
            Node@ _node = scene.children[i];
            if (_node.name.StartsWith("Cover"))
            {
                CreateLine(LINE_COVER, _node);
            }
            else if (_node.name.StartsWith("Railing"))
            {
                CreateLine(LINE_RAILING, _node);
            }
            else if (_node.name.StartsWith("ClimbOver"))
            {
                CreateLine(LINE_EDGE, _node);
            }
            else if (_node.name.StartsWith("ClimbUp"))
            {
                CreateLine(LINE_EDGE, _node);
            }
            else if (_node.name.StartsWith("ClimbHang"))
            {
                CreateLine(LINE_EDGE, _node);
            }
            else if (_node.name.StartsWith("Dangle"))
            {
                CreateLine(LINE_EDGE, _node);
            }
        }
    }

    Line@ GetNearestLine(const Vector3& pos, float angle, float maxDistance)
    {
        Line@ ret = null;
        for (uint i=0; i<lines.length; ++i)
        {
            Line@ l = lines[i];
            float dist = l.Test(pos, angle);
            if (dist < 0)
                continue;

            if (dist < maxDistance)
            {
                maxDistance = dist;
                @ret = l;
            }
        }
        return ret;
    }

    void CollectLines(const Vector3& pos, float angle, float maxDistance)
    {
        cacheLines.Clear();
        for (uint i=0; i<lines.length; ++i)
        {
            Line@ l = lines[i];
            float dist = l.Test(pos, angle);
            if (dist < 0)
                continue;
            if (dist < maxDistance)
                cacheLines.Push(l);
        }
    }

    int CollectLinesByNode(Node@ node, Array<Line@>@ outLines)
    {
        // outLines.Clear();

        for (uint i=0; i<lines.length; ++i)
        {
            if (lines[i].nodeId == node.id)
                outLines.Push(lines[i]);
        }

        Print("CollectLinesByNode " + node.name + " num=" + outLines.length);

        return outLines.length;
    }
};


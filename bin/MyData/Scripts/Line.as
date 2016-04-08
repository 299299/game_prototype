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
    LINE_CLIMB_OVER,
    LINE_CLIMB_UP,
    LINE_RAILING,
    LINE_CLIMB_HANG,
    LINE_DANGLE,
    LINE_TYPE_NUM
};

class Line
{
    Ray             ray;
    Vector3         end;
    Vector3         invDir;
    float           length;
    float           lengthSquared;
    int             type;
    float           angle;
    int             flag;
    float           maxHeight;
    float           maxFacingDiff = 45;

    Vector3 Project(const Vector3& charPos)
    {
        return ray.Project(charPos);
    }

    bool IsProjectPositionInLine(const Vector3& proj, float bound = 1.0f)
    {
        float l_to_start = (proj - ray.origin).length;
        float l_to_end = (proj - end).length;
        // check if project is in line
        if (l_to_start > length || l_to_end > length)
            return false;
        // check if project is in bound
        return l_to_start >= bound && l_to_end >= bound;
    }

    Vector3 FixProjectPosition(const Vector3& proj, float bound = 1.0f)
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
        Print("FixProjectPosition");
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

    int Test(const Vector3& pos, float angle, Vector3& out project, float&out outDistance)
    {
        float yDiff = end.y - pos.y;
        if (Abs(yDiff) > maxHeight)
            return 0;

        if (type == LINE_CLIMB_OVER || type == LINE_CLIMB_UP)
        {
            float h_diff = end.y - pos.y;
            if (h_diff < 1.0f)
                return 0;
        }

        project = ray.Project(pos);
        if (!IsProjectPositionInLine(project))
            return 0;

        project.y = pos.y;
        Vector3 dir = project - pos;
        float projDir = Atan2(dir.x, dir.z);
        float aDiff = AngleDiff(projDir - angle);
        if (Abs(aDiff) > maxFacingDiff)
            return 0;

        outDistance = dir.length;
        return 1;
    }

    void DebugDraw(DebugRenderer@ debug, const Color&in color)
    {
        debug.AddCross(ray.origin, 0.25f, RED, false);
        debug.AddCross(end, 0.25f, BLUE, false);
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
};

float GetCorners(Node@ n, Vector3&out p1, Vector3&out p2, Vector3&out p3, Vector3&out p4)
{
    CollisionShape@ shape = n.GetComponent("CollisionShape");
    if (shape is null)
        return -1;

    Vector3 halfSize = shape.size/2;
    Vector3 offset = shape.position;

    p1 = Vector3(halfSize.x, halfSize.y, halfSize.z);
    p2 = Vector3(halfSize.x, halfSize.y, -halfSize.z);
    p3 = Vector3(-halfSize.x, halfSize.y, -halfSize.z);
    p4 = Vector3(-halfSize.x, halfSize.y, halfSize.z);
    p1 = n.LocalToWorld(p1 + offset);
    p2 = n.LocalToWorld(p2 + offset);
    p3 = n.LocalToWorld(p3 + offset);
    p4 = n.LocalToWorld(p4 + offset);

    return halfSize.y * 2 * n.worldScale.y;
}

float GetCorners(Node@ n, Vector3&out p1, Vector3&out p2)
{
    CollisionShape@ shape = n.GetComponent("CollisionShape");
    if (shape is null)
        return -1;

    Vector3 halfSize = shape.size/2;
    Vector3 offset = shape.position;

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

    return halfSize.y * 2 * n.worldScale.y;
}

class LineWorld
{
    Array<Line@>            lines;
    Array<Color>            debugColors;
    Array<Line@>            cacheLines;

    LineWorld()
    {
        debugColors.Resize(LINE_TYPE_NUM);
        debugColors[LINE_CLIMB_OVER] = GREEN;
        debugColors[LINE_RAILING] = BLUE;
        debugColors[LINE_COVER] = YELLOW;
        debugColors[LINE_CLIMB_UP] = Color(0.25f, 0.5f, 0.75f);
        debugColors[LINE_CLIMB_HANG] = Color(0.65f, 0.25f, 0.25f);
        debugColors[LINE_DANGLE] = Color(0.35f, 0.75f, 0.25f);
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

    Line@ CreateLine(int type, const Vector3&in start, const Vector3&in end, float h)
    {
        Vector3 dir = end - start;
        float lenSQR = dir.lengthSquared;
        if (lenSQR < 0.5f*0.5f)
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
        l.maxHeight = h;
        AddLine(l);
        return l;
    }

    void CreateLine(int type, Node@ n)
    {
        float adjustH = 2.0f;
        if (type == LINE_CLIMB_UP || type == LINE_CLIMB_HANG)
        {
            Vector3 p1, p2, p3, p4;
            float h = GetCorners(n, p1, p2, p3, p4);
            if (h <= 0)
                return;
            CreateLine(type, p1, p2, h + adjustH);
            CreateLine(type, p2, p3, h + adjustH);
            CreateLine(type, p3, p4, h + adjustH);
            CreateLine(type, p4, p1, h + adjustH);
        }
        else
        {
            Vector3 p1, p2;
            float h = GetCorners(n, p1, p2);
            if (h <= 0)
                return;
            CreateLine(type, p1, p2, h + adjustH);
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
                CreateLine(LINE_CLIMB_OVER, _node);
            }
            else if (_node.name.StartsWith("ClimbUp"))
            {
                CreateLine(LINE_CLIMB_UP, _node);
            }
            else if (_node.name.StartsWith("ClimbHang"))
            {
                CreateLine(LINE_CLIMB_HANG, _node);
            }
            else if (_node.name.StartsWith("Dangle"))
            {
                CreateLine(LINE_DANGLE, _node);
            }
        }
    }

    Line@ GetNearestLine(const Vector3& pos, float angle, float maxDistance)
    {
        Line@ ret = null;
        Vector3 project;

        for (uint i=0; i<lines.length; ++i)
        {
            float dist = 999;
            Line@ l = lines[i];
            if (l.Test(pos, angle, project, dist) == 0)
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
            float dist = 999;
            Line@ l = lines[i];
            Vector3 project;
            if (l.Test(pos, angle, project, dist) == 0)
                continue;
            if (dist < maxDistance)
                cacheLines.Push(l);
        }
    }
};
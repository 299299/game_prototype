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

    uint            nodeId;

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

    int GetTowardHead(float towardAngle)
    {
        float angleDiff = Abs(AngleDiff(angle - towardAngle));
        if (angleDiff > 90)
            return 0;
        return 1;
    }

    int Test(const Vector3& pos, float angle, Vector3& out project, float&out outDistance)
    {
        float yDiff = end.y - pos.y;
        if (Abs(yDiff) > maxHeight)
            return 0;

        /*
        if (type == LINE_CLIMB_OVER || type == LINE_CLIMB_UP)
        {
            float h_diff = end.y - pos.y;
            if (h_diff < 1.0f)
                return 0;
        }
        */

        if (type == LINE_CLIMB_OVER || type == LINE_CLIMB_HANG)
        {
            float h_diff = end.y - pos.y;
            if (h_diff < 1.5f)
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
    //Array<float>            cacheError;

    LineWorld()
    {
        debugColors.Resize(LINE_TYPE_NUM);
        debugColors[LINE_CLIMB_OVER] = Color(0.4f, 0.75f, 0.3f);
        debugColors[LINE_RAILING] = Color(0.25f, 0.25f, 0.75f);
        debugColors[LINE_COVER] = Color(0.75f, 0.15f, 0.15f);
        debugColors[LINE_CLIMB_UP] = Color(0.25f, 0.5f, 0.75f);
        debugColors[LINE_CLIMB_HANG] = Color(0.65f, 0.25f, 0.55f);
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

    Line@ CreateLine(int type, const Vector3&in start, const Vector3&in end, float h, uint nodeId)
    {
        Vector3 dir = end - start;
        float lenSQR = dir.lengthSquared;
        float maxError = 2.0f;
        if (lenSQR < maxError*maxError)
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
        l.nodeId = nodeId;
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
            CreateLine(type, p1, p2, h + adjustH, n.id);
            CreateLine(type, p2, p3, h + adjustH, n.id);
            CreateLine(type, p3, p4, h + adjustH, n.id);
            CreateLine(type, p4, p1, h + adjustH, n.id);
        }
        else
        {
            Vector3 p1, p2;
            float h = GetCorners(n, p1, p2);
            if (h <= 0)
                return;
            CreateLine(type, p1, p2, h + adjustH, n.id);
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

    void CollectCloseCrossLine(Line@ l, const Vector3& linePt)
    {
        float distSQRError = 0.25f * 0.25f;
        float distSQRError1 = 0.5f * 0.5f;
        cacheLines.Clear();
        //cacheError.Clear();

        for (uint i=0; i<lines.length; ++i)
        {
            Line@ line = lines[i];
            if (l is line)
                continue;

            if (l.type != line.type)
                continue;

            Vector3 proj = line.Project(linePt);
            float proj_sqr = (proj - linePt).lengthSquared;
            if (proj_sqr > distSQRError)
                continue;

            float start_sqr = (line.ray.origin - linePt).lengthSquared;
            float end_sqr = (line.end - linePt).lengthSquared;
            if (start_sqr > distSQRError1 && end_sqr > distSQRError1)
                continue;

            float angle_diff = Abs(AngleDiff(l.angle - line.angle));
            float diff_90 = Abs(angle_diff - 90);

            // Print("in-angle=" + l.angle + " out-angle=" + line.angle + " angle_diff=" + angle_diff);
            if (diff_90 > 5)
                continue;

            cacheLines.Push(line);
            //cacheError.Push(proj_sqr);
        }
    }

    Line@ FindCloseParallelLine(Line@ l, const Vector3& linePt, float maxHeightDiff, float maxDistance)
    {
        Line@ ret = null;
        float maxDistanceSQR = maxDistance*maxDistance;
        float maxDistError = 0.5f;

        for (uint i=0; i<lines.length; ++i)
        {
            Line@ line = lines[i];
            if (l is line)
                continue;

            if (l.type != line.type)
                continue;

            float angle_diff = Abs(AngleDiff(l.angle - line.angle));
            if (angle_diff > 5)
                continue;

            float start_sqr = (line.ray.origin - linePt).lengthSquared;
            float end_sqr = (line.end - linePt).lengthSquared;
            if (start_sqr > maxDistanceSQR && end_sqr > maxDistanceSQR)
                continue;

            float heightDiff = Abs(l.end.y - line.end.y);
            if (heightDiff > maxHeightDiff)
                continue;

            Vector3 v = linePt;
            v.y = line.end.y;
            float dist = line.ray.Distance(v);
            if (dist > maxDistError)
                continue;

            float dist_sqr = Min(start_sqr, end_sqr);
            if (dist_sqr < maxDistanceSQR)
            {
                maxDistanceSQR = dist_sqr;
                @ret = line;
            }
        }

        return ret;
    }
};


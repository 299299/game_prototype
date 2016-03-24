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
    LINE_TYPE_NUM
};

class Line
{
    Ray             ray;
    Vector3         end;
    float           length;
    float           lengthSquared;
    int             type;
    float           angle;
    int             flag;
    float           maxHeight;

    Vector3 Project(const Vector3& charPos)
    {
        return ray.Project(charPos);
    }

    bool IsProjectPositionInLine(const Vector3& proj)
    {
        float l_to_start = (proj - ray.origin).lengthSquared;
        float l_to_end = (proj - end).lengthSquared;
        if (l_to_start > lengthSquared || l_to_end > lengthSquared)
            return false;
        return true;
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

    float GetProjFacingDiff(const Vector3& pos, float angle)
    {
        Vector3 proj = Project(pos);
        proj.y = pos.y;
        Vector3 dir = proj - pos;
        float projDir = Atan2(dir.x, dir.z);
        float aDiff = AngleDiff(projDir - angle);
        return Abs(aDiff);
    }

    int TestPosition(const Vector3& pos)
    {
        float yDiff = end.y - pos.y;
        if (Abs(yDiff) > maxHeight)
            return 0;

        if (type == LINE_CLIMB_OVER || type == LINE_CLIMB_UP)
        {
            float h_diff = end.y - pos.y;
            if (h_diff < 3.0f)
                return 0;
            return 1;
        }
        return 1;
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
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        for (uint i=0; i<lines.length; ++i)
        {
            Line@ l = lines[i];
            debug.AddCross(l.ray.origin, 0.25f, RED, false);
            debug.AddCross(l.end, 0.25f, BLUE, false);
            debug.AddLine(l.ray.origin, l.end, debugColors[l.type], false);
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
        l.length = dir.length;
        l.lengthSquared = lenSQR;
        l.angle = Atan2(dir.x, dir.z);
        l.maxHeight = h;
        AddLine(l);
        return l;
    }

    void Process(Scene@ scene)
    {
        Vector3 p1, p2, p3, p4;
        float h = 0;

        for (uint i=0; i<scene.numChildren; ++i)
        {
            Node@ _node = scene.children[i];
            if (_node.name.StartsWith("Cover"))
            {
                h = GetCorners(_node, p1, p2, p3, p4);
                if (h <= 0)
                    continue;
                CreateLine(LINE_COVER, p1, p2, h + 3.0f);
                CreateLine(LINE_COVER, p2, p3, h + 3.0f);
                CreateLine(LINE_COVER, p3, p4, h + 3.0f);
                CreateLine(LINE_COVER, p4, p1, h + 3.0f);
            }
            else if (_node.name.StartsWith("Railing"))
            {
                h = GetCorners(_node, p1, p2, p3, p4);
                if (h <= 0)
                    continue;
                CreateLine(LINE_RAILING, p1, p2, h + 3.0f);
                CreateLine(LINE_RAILING, p2, p3, h + 3.0f);
                CreateLine(LINE_RAILING, p3, p4, h + 3.0f);
                CreateLine(LINE_RAILING, p4, p1, h + 3.0f);
            }
            else if (_node.name.StartsWith("ClimbOver"))
            {
                h = GetCorners(_node, p1, p2, p3, p4);
                if (h <= 0)
                    continue;
                CreateLine(LINE_CLIMB_OVER, p1, p2, h + 3.0f);
                CreateLine(LINE_CLIMB_OVER, p2, p3, h + 3.0f);
                CreateLine(LINE_CLIMB_OVER, p3, p4, h + 3.0f);
                CreateLine(LINE_CLIMB_OVER, p4, p1, h + 3.0f);
            }
            else if (_node.name.StartsWith("ClimbUp"))
            {
                h = GetCorners(_node, p1, p2, p3, p4);
                if (h <= 0)
                    continue;
                CreateLine(LINE_CLIMB_UP, p1, p2, h + 3.0f);
                CreateLine(LINE_CLIMB_UP, p2, p3, h + 3.0f);
                CreateLine(LINE_CLIMB_UP, p3, p4, h + 3.0f);
                CreateLine(LINE_CLIMB_UP, p4, p1, h + 3.0f);
            }
        }
    }

    Line@ GetNearestLine(const Vector3& charPos, float maxDistance)
    {
        Line@ ret = null;
        float minDist = maxDistance;
        for (uint i=0; i<lines.length; ++i)
        {
            Line@ l = lines[i];
            if (l.TestPosition(charPos) == 0)
                continue;

            Vector3 project = l.ray.Project(charPos);
            if (!l.IsProjectPositionInLine(project))
                continue;

            project.y = charPos.y;
            float dist = (charPos - project).length;
            // Print("dist = " + dist);
            if (dist < minDist)
            {
                minDist = dist;
                @ret = l;
            }
        }
        return ret;
    }

    void CollectLines(const Vector3& charPos, float maxDistance)
    {
        cacheLines.Clear();
        for (uint i=0; i<lines.length; ++i)
        {
            Line@ l = lines[i];
            if (l.TestPosition(charPos) == 0)
                continue;
            Vector3 project = l.ray.Project(charPos);
            if (!l.IsProjectPositionInLine(project))
                continue;
            project.y = charPos.y;
            float dist = (charPos - project).length;
            // Print("dist = " + dist);
            if (dist < maxDistance)
                cacheLines.Push(l);
        }
    }
};
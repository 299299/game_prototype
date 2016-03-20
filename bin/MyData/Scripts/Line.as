

enum LineType
{
    LINE_CLIMB_EDGE,
    LINE_RAILING,
    LINE_WALK_EDGE,
    LINE_COVER,
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
};


class LineWorld
{
    Array<Line@>            lines;
    Array<Color>            debugColors;

    LineWorld()
    {
        debugColors.Resize(LINE_TYPE_NUM);
        debugColors[LINE_CLIMB_EDGE] = Color(0.15f, 0.25f, 3.0f);
        debugColors[LINE_RAILING] = BLUE;
        debugColors[LINE_COVER] = YELLOW;
        debugColors[LINE_WALK_EDGE] = GREEN;
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

    void Process(Scene@ scene)
    {
        for (uint i=0; i<scene.numChildren; ++i)
        {
            Node@ _node = scene.children[i];
            if (_node.name.StartsWith("Cover"))
            {
                Line@ l = Line();
                l.ray.origin = _node.GetChild("start", false).worldPosition;
                l.end = _node.GetChild("end", false).worldPosition;
                l.type = LINE_COVER;
                Vector3 dir = l.end - l.ray.origin;
                l.ray.direction = dir.Normalized();
                l.length = dir.length;
                l.lengthSquared = dir.lengthSquared;
                l.angle = Atan2(dir.x, dir.z);
                AddLine(l);
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
            Vector3 project = l.ray.Project(charPos);
            if (!l.IsProjectPositionInLine(project))
                continue;

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
};
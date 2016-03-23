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
                l.maxHeight = 7.0f;
                AddLine(l);
            }
            else if (_node.name.StartsWith("Railing"))
            {
                Line@ l = Line();
                l.ray.origin = _node.GetChild("start", false).worldPosition;
                l.end = _node.GetChild("end", false).worldPosition;
                l.type = LINE_RAILING;
                Vector3 dir = l.end - l.ray.origin;
                l.ray.direction = dir.Normalized();
                l.length = dir.length;
                l.lengthSquared = dir.lengthSquared;
                l.angle = Atan2(dir.x, dir.z);
                l.maxHeight = 12.0f;
                AddLine(l);
            }
            else if (_node.name.StartsWith("ClimbOver"))
            {
                Line@ l = Line();
                l.ray.origin = _node.GetChild("start", false).worldPosition;
                l.end = _node.GetChild("end", false).worldPosition;
                l.type = LINE_CLIMB_OVER;
                Vector3 dir = l.end - l.ray.origin;
                l.ray.direction = dir.Normalized();
                l.length = dir.length;
                l.lengthSquared = dir.lengthSquared;
                l.angle = Atan2(dir.x, dir.z);
                l.maxHeight = 12.0f;
                AddLine(l);
            }
            else if (_node.name.StartsWith("ClimbUp"))
            {
                Line@ l = Line();
                l.ray.origin = _node.GetChild("start", false).worldPosition;
                l.end = _node.GetChild("end", false).worldPosition;
                l.type = LINE_CLIMB_UP;
                Vector3 dir = l.end - l.ray.origin;
                l.ray.direction = dir.Normalized();
                l.length = dir.length;
                l.lengthSquared = dir.lengthSquared;
                l.angle = Atan2(dir.x, dir.z);
                l.maxHeight = 12.0f;
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


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
    Vector3         start;
    Vector3         end;
    int             type;
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
            debug.AddCross(l.start, 0.25f, RED, false);
            debug.AddCross(l.end, 0.25f, BLUE, false);
            debug.AddLine(l.start, l.end, debugColors[l.type], false);
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
                l.start = _node.GetChild("start", false).worldPosition;
                l.end = _node.GetChild("end", false).worldPosition;
                l.type = LINE_COVER;
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
            float dist = DistToLine(charPos, l.start, l.end);
            // Print("DistToLine " + i + " = " + dist);
            if (dist < minDist)
            {
                minDist = dist;
                @ret = l;
            }
        }
        return ret;
    }

    //-- get the minimum distance from a point to a line
    float DistToLine(const Vector3& point, const Vector3& start, const Vector3& end)
    {
        Vector3 lineVector = end - start;
        Vector3 lineToPoint = point - start;

        //-- project the point onto the line
        float t = lineToPoint.DotProduct(lineVector);

        // -- clamp at the minimum boundary
        if (t < 0)
            return lineToPoint.length;

        // -- normalize scale and clamp at max boundary
        t /= lineVector.lengthSquared;
        if (t > 1)
            t = 1;

        //-- get the minimum vector from the line to the point
        lineToPoint = start + lineVector * t;
        lineVector = point - lineToPoint;

        // -- return the length of the minimum vector
        return lineVector.length;
    }
};
//
//
//  128 --> 3.25
//  256 --> 6.5
//  384 --> 9.75
//
//

const float HEIGHT_128 = 3.25f;
const float HEIGHT_256 = HEIGHT_128 * 2;
const float HEIGHT_384 = HEIGHT_128 * 3;

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
    float           invalidAngleSide = 999;

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

        // test facing angle
        float aDiff = Abs(AngleDiff(projDir - angle));
        if (aDiff > maxFacingDiff)
            return -1;

        // test invalid angle side
        if (invalidAngleSide < 360) {
            aDiff = Abs(AngleDiff(projDir + 180 - invalidAngleSide));
            if (aDiff < 90)
            {
                return -1;
            }
        }

        return dir.length;
    }

    bool IsAngleValid(float theAngle)
    {
        return invalidAngleSide > 360 ? true : (Abs(AngleDiff(theAngle - invalidAngleSide)) < 90);
    }

    void DebugDraw(DebugRenderer@ debug, const Color&in color)
    {
        //debug.AddCross(ray.origin, 0.25f, RED, false);
        //debug.AddCross(end, 0.25f, BLUE, false);
        debug.AddSphere(Sphere(ray.origin, 0.15f), YELLOW, false);
        debug.AddSphere(Sphere(end, 0.15f), YELLOW, false);
        debug.AddLine(ray.origin, end, color, false);
        if (invalidAngleSide < 360)
            DebugDrawDirection(debug, (ray.origin + end)/2, invalidAngleSide, RED);
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

int GetCorners(Node@ n, Vector3&out outSize, Array<Vector3>@ points)
{
    Vector3 size, offset;
    if (!GetNodeSizeAndOffset(n, size, offset))
        return 0;

    Vector3 halfSize = size/2;
    float x = size.x * n.worldScale.x;
    float z = size.z * n.worldScale.z;

    if (x < LINE_MIN_LENGTH || z < LINE_MIN_LENGTH)
    {
        if (x > z)
        {
            points.Push(Vector3(halfSize.x, halfSize.y, 0));
            points.Push(Vector3(-halfSize.x, halfSize.y, 0));
        }
        else
        {
            points.Push(Vector3(0, halfSize.y, halfSize.z));
            points.Push(Vector3(0, halfSize.y, -halfSize.z));
        }
    }
    else
    {
        points.Push(Vector3(halfSize.x, halfSize.y, halfSize.z));
        points.Push(Vector3(halfSize.x, halfSize.y, -halfSize.z));
        points.Push(Vector3(-halfSize.x, halfSize.y, -halfSize.z));
        points.Push(Vector3(-halfSize.x, halfSize.y, halfSize.z));
    }

    for (uint i=0; i<points.length; ++i)
        points[i] = n.LocalToWorld(points[i] + offset);

    outSize = size * n.worldScale;
    return int(points.length);
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
        // Print("CreateLine type=" + type + " for node=" + node.name + " size=" + size.ToString() + " flags=" + l.flags);
        return l;
    }

    void CreateLine(int type, Node@ n)
    {
        Vector3 size;
        Array<Vector3> points;

        if (GetCorners(n, size, points) < 2)
            return;



        if (points.length == 4)
        {
            Line@ l1 = CreateLine(type, points[0], points[1], size, n);
            Line@ l2 = CreateLine(type, points[1], points[2], size, n);
            Line@ l3 = CreateLine(type, points[2], points[3], size, n);
            Line@ l4 = CreateLine(type, points[3], points[0], size, n);
            Vector3 dir = points[2] - points[1];
            l1.invalidAngleSide = Atan2(dir.x, dir.z);
            dir = points[3] - points[2];
            l2.invalidAngleSide = Atan2(dir.x, dir.z);
            dir = points[0] - points[3];
            l3.invalidAngleSide = Atan2(dir.x, dir.z);
            dir = points[1] - points[0];
            l4.invalidAngleSide = Atan2(dir.x, dir.z);
        }
        else
        {
            for (uint i=0; i<points.length-1; ++i)
            {
                CreateLine(type, points[i], points[i+1], size, n);
            }
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
            else if (_node.name.StartsWith("Edge"))
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

    int CollectLinesInBox(Scene@ scene, const BoundingBox& box, uint nodeToIgnore, Array<Line@>@ outLines)
    {
        outLines.Clear();

        Array<RigidBody@> bodies = scene.physicsWorld.GetRigidBodies(box, COLLISION_LAYER_LANDSCAPE);
        Print("CollectLinesInBox bodies.num=" + bodies.length);
        if (bodies.empty)
            return 0;

        for (uint i=0; i<bodies.length; ++i)
        {
            Node@ n = bodies[i].node;
            if (n.id == nodeToIgnore)
                continue;
            CollectLinesByNode(n, outLines);
        }

        return outLines.length;
    }
};



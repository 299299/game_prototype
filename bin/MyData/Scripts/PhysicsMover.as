
class PhysicsMover
{
    bool        grounded = true;
    Node@       sceneNode;

    Vector3     start, end;

    float       inAirHeight = 0.0f;
    int         inAirFrames = 0;

    float       halfHeight = CHARACTER_HEIGHT / 2;

    PhysicsMover(Node@ n)
    {
        sceneNode = n;
    }

    ~PhysicsMover()
    {
        Remove();
    }

    void Remove()
    {
        @sceneNode = null;
    }

    void DetectGround()
    {
        start = sceneNode.worldPosition;
        end = start;
        start.y += halfHeight;
        float addlen = 30.0f;
        end.y -= addlen;

        PhysicsRaycastResult result = PhysicsSphereCast(start, end, 0.25f, COLLISION_LAYER_LANDSCAPE);

        if (result.body !is null)
        {
            end = result.position;

            float h = start.y - end.y;
            if (h > halfHeight + 0.5f)
                grounded = false;
            else
                grounded = true;
            inAirHeight = h;
        }
        else
        {
            grounded = false;
            inAirHeight = addlen + 1;
        }

        if (grounded)
        {
            inAirFrames = 0;
            inAirHeight = 0.0f;
        }
        else
        {
            inAirFrames ++;
        }
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        debug.AddLine(start, end, grounded ? GREEN : RED, false);
    }

    Vector3 GetGround(const Vector3&in pos)
    {
        Vector3 start = pos;
        start.y += 1.0f;
        Ray ray;
        ray.Define(start, Vector3(0, -1, 0));
        PhysicsRaycastResult result = sceneNode.scene.physicsWorld.RaycastSingle(ray, 30.0f, COLLISION_LAYER_LANDSCAPE);
        return (result.body !is null) ? result.position : end;
    }

    void MoveTo(const Vector3&in pos)
    {
        Vector3 oldPos = sceneNode.worldPosition;
        oldPos.y += CHARACTER_HEIGHT / 2.0f;
        Vector3 newPos = pos;
        newPos.y += CHARACTER_HEIGHT / 2.0f;
        PhysicsRaycastResult result = PhysicsSphereCast(oldPos, newPos, 0.25f, COLLISION_LAYER_LANDSCAPE);
        if (result.body is null)
            sceneNode.worldPosition = pos;
        else
        {
            sceneNode.worldPosition = result.normal * COLLISION_RADIUS + result.position;
        }
        //sceneNode.worldPosition = FilterPosition(position);
    }
};
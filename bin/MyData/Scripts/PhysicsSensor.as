
class PhysicsSensor
{
    bool        grounded = true;
    Node@       sceneNode;
    Node@       sensorNode;

    CollisionShape@  shape;

    Vector3     start, end;

    float       inAirHeight = 0.0f;
    int         inAirFrames = 0;

    float       halfHeight = CHARACTER_HEIGHT / 2;

    PhysicsSensor(Node@ n)
    {
        sceneNode = n;
        sensorNode = sceneNode.CreateChild("SensorNode");
        shape = sensorNode.CreateComponent("CollisionShape");
        shape.SetCapsule(COLLISION_RADIUS, CHARACTER_HEIGHT, Vector3(0.0f, CHARACTER_HEIGHT/2, 0.0f));
    }

    ~PhysicsSensor()
    {
        shape.Remove();
    }

    void Update(float dt)
    {
        start = sceneNode.worldPosition;
        end = start;
        start.y += halfHeight;
        float addlen = 30.0f;
        end.y -= addlen;

        PhysicsRaycastResult result = sceneNode.scene.physicsWorld.ConvexCast(shape, start, Quaternion(), end, Quaternion(), COLLISION_LAYER_LANDSCAPE | COLLISION_LAYER_PROP);

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
};
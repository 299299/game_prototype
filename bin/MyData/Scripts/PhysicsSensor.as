
class PhysicsSensor
{
    bool        grounded = false;
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

        PhysicsRaycastResult result = sceneNode.scene.physicsWorld.ConvexCast(shape, start, Quaternion(), end, Quaternion(), COLLISION_LAYER_LANDSCAPE);

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
};
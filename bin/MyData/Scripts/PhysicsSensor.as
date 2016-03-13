
class PhysicsSensor
{
    bool        grounded = false;
    Node@       sceneNode;

    Vector3     gV1, gV2;

    PhysicsSensor(Node@ n)
    {
        sceneNode = n;
    }

    void Update(float dt)
    {
        gV1 = sceneNode.worldPosition;
        gV2 = gV1;
        gV1.y += CHARACTER_HEIGHT / 2;
        float addlen = 0.5f;
        gV2.y -= addlen;

        Ray ray;
        ray.origin = gV1;
        ray.direction = (gV2 - gV1).Normalized();

        PhysicsRaycastResult result = sceneNode.scene.physicsWorld.RaycastSingle(ray, CHARACTER_HEIGHT/2 + addlen, COLLISION_LAYER_LANDSCAPE);
        grounded = result.body !is null;

        if (grounded)
        {
            gV2 = result.position;
        }
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        debug.AddLine(gV1, gV2, grounded ? GREEN : RED, false);
    }
};
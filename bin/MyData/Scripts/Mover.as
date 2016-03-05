

class Mover
{
    Node@           sceneNode;
    int             type;

    Vector3         rayV1_Start, rayV1_End;

    float           skinWidth = 0.25f;

    bool            grounded = false;

    Mover()
    {

    }

    ~Mover()
    {
        sceneNode = null;
    }

    void MoveTo(const Vector3&in position, float dt)
    {
        Vector3 v = FilterPosition(position);
        if (type == 0)
            sceneNode.worldPosition = v;
        else if (type == 1)
        {
            Vector3 oldPos = sceneNode.worldPosition;
            Vector3 vel = (v - oldPos) / dt;
            Vector3 next_pos_one_sec = oldPos + vel;
            Vector3 hitPoint;
            float hitDis;
            float velLen = vel.length;
            float halfHeight = CHARACTER_HEIGHT/2;
            Vector3 startV1(oldPos.x, oldPos.y + halfHeight, oldPos.z);
            Vector3 endV1(next_pos_one_sec.x, oldPos.y + halfHeight, next_pos_one_sec.z);
            bool bHit = Raycast(startV1, endV1, velLen, hitPoint, hitDis);
            rayV1_Start = startV1;
            rayV1_End = bHit ? hitPoint : endV1;
            if (bHit && (hitDis <= (COLLISION_RADIUS + skinWidth)))
                return;
            sceneNode.worldPosition = v;
        }
    }

    bool Raycast(const Vector3&in start, const Vector3&in end, float len, Vector3&out hitPoint, float&out hitDis)
    {
        Ray ray(start, (end - start).Normalized());
        PhysicsRaycastResult result = sceneNode.scene.physicsWorld.RaycastSingle(ray, len, COLLISION_LAYER_LANDSCAPE);
        if (result.body is null)
            return false;
        hitPoint = start + ray.direction * result.distance;
        hitDis = result.distance;
        return true;
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        if (type == 1)
        {
            debug.AddLine(rayV1_Start, rayV1_End, RED, false);
        }
    }
};
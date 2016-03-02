

class Mover
{
    Node@           sceneNode;
    int             type;

    Vector3         hitPoint1;
    Vector3         hitPoint2;

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
            Vector3 v1_start = sceneNode.worldPosition;
            Vector3 v2_start(v1.x, v1.y + CHARACTER_HEIGHT, v1.z);

        }
    }

    void DebugDraw(DebugRenderer@ debug)
    {

    }
};
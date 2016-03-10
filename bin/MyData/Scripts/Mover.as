

class Mover
{
    Node@           sceneNode;
    int             type;
    bool            grounded = false;

    RigidBody@      body;

    Mover(Node@ n)
    {
        sceneNode = n;
    }

    ~Mover()
    {
        sceneNode = null;
    }

    void Start(int t)
    {
        type = t;
        if (type == 1)
        {
            body = sceneNode.CreateComponent("RigidBody");
            body.collisionLayer = COLLISION_LAYER_CHARACTER;
            body.mass = 1.0f;
            body.angularFactor = Vector3(0.0f, 0.0f, 0.0f);
            body.collisionEventMode = COLLISION_ALWAYS;
            CollisionShape@ shape = sceneNode.CreateComponent("CollisionShape");
            shape.SetCapsule(COLLISION_RADIUS*2, CHARACTER_HEIGHT, Vector3(0.0f, CHARACTER_HEIGHT/2, 0.0f));
        }
    }

    void MoveTo(const Vector3&in position, float dt)
    {
        Vector3 v = FilterPosition(position);
        if (body !is null)
        {
            body.linearVelocity = (v - sceneNode.worldPosition) / dt;
        }
        else
            sceneNode.worldPosition = v;
    }

    void DebugDraw(DebugRenderer@ debug)
    {

    }

    void Clear()
    {
        if (body !is null)
            body.linearVelocity = Vector3(0, 0, 0);
    }
};
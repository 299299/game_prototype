

class Follow : ScriptObject
{
    uint toFollow = M_MAX_UNSIGNED;
    float speed = 5.0f;
    Vector3 offset = Vector3(0, 5, 0);

    void Update(float dt)
    {
        Node@ n = scene.GetNode(toFollow);
        if (n is null)
            return;

        Vector3 myPos = node.worldPosition;
        Vector3 targetPos = n.worldPosition + offset;
        node.worldPosition = myPos + (targetPos - myPos) * dt * speed;
    }
};
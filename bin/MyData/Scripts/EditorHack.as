float GetCorners(Node@ n, Vector3&out p1, Vector3&out p2, Vector3&out p3, Vector3&out p4)
{
    CollisionShape@ shape = n.GetComponent("CollisionShape");
    if (shape is null)
        return -1;

    Vector3 halfSize = shape.size/2;
    Vector3 offset = shape.position;

    p1 = Vector3(halfSize.x, halfSize.y, halfSize.z);
    p2 = Vector3(halfSize.x, halfSize.y, -halfSize.z);
    p3 = Vector3(-halfSize.x, halfSize.y, -halfSize.z);
    p4 = Vector3(-halfSize.x, halfSize.y, halfSize.z);
    p1 = n.LocalToWorld(p1 + offset);
    p2 = n.LocalToWorld(p2 + offset);
    p3 = n.LocalToWorld(p3 + offset);
    p4 = n.LocalToWorld(p4 + offset);

    return halfSize.y * 2 * n.worldScale.y;
}

void UpdateEditorHack(float dt)
{
    if (input.keyPress[KEY_1])
    {
        // print current information
        for (uint i = 0; i < editNodes.length; ++i)
        {
            Node@ _n = editNodes[i];
            Print(_n.name + " world-pos=" + _n.worldPosition.ToString() + " world-rot=" + _n.worldRotation.eulerAngles.ToString());
        }
    }
    else if (input.keyPress[KEY_2])
    {
        AnimationState@ animState = testAnimState.Get();
        if (animState !is null)
            animState.AddTime(-1.0f/30.0f);
    }
    else if (input.keyPress[KEY_3])
    {
        AnimationState@ animState = testAnimState.Get();
        if (animState !is null)
            animState.AddTime(1.0f/30.0f);
    }
    else if (input.keyPress[KEY_4])
    {
        if (editNodes.length < 2)
            return;

        Node@ boneNode = editNodes[0];
        Node@ boxNode = editNodes[1];
        if (!boneNode.name.StartWith("Bip"))
        {
            boneNode = editNodes[1];
            boxNode = editNodes[0];
        }
`
        Vector3 p1, p2, p3, p4;
        float h = GetCorners(boxNode, p1, p2, p3, p4);
        if (h <= 0)
            return;


    }
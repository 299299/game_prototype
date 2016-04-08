
float GetCorners(Node@ n, Vector3&out p1, Vector3&out p2, Vector3&out p3, Vector3&out p4)
{
    StaticModel@ model = n.GetComponent("StaticModel");
    if (model is null)
        return -1;
    Vector3 halfSize = model.boundingBox.halfSize;
    p1 = Vector3(halfSize.x, halfSize.y, halfSize.z);
    p2 = Vector3(halfSize.x, halfSize.y, -halfSize.z);
    p3 = Vector3(-halfSize.x, halfSize.y, -halfSize.z);
    p4 = Vector3(-halfSize.x, halfSize.y, halfSize.z);
    p1 = n.LocalToWorld(p1);
    p2 = n.LocalToWorld(p2);
    p3 = n.LocalToWorld(p3);
    p4 = n.LocalToWorld(p4);
    return halfSize.y * 2 * n.worldScale.y;
}

float GetDistance(const Vector3&in start, const Vector3&in end, const Vector3&in pt)
{
    Ray ray(start, (end-start).Normalized());
    Vector3 proj = ray.Project(pt);
    return (pt - proj).length;
}

AnimationState@ GetEditingAnimationState()
{
    Node@ _node = editorScene.GetChild("bruce_w", true);
    if (_node is null)
        return null;
    AnimatedModel@ model = _node.GetComponent("AnimatedModel");
    if (model is null)
    {
        model = _node.children[0].GetComponent("AnimatedModel");
        if (model is null)
            return null;
    }
    if (model.numAnimationStates == 0)
        return null;
    return model.GetAnimationState(0);
}

void UpdateEditorHack(float dt)
{
    if (input.keyPress[KEY_1])
    {
        if (editNodes.empty)
            return;

        // print current information
        Node@ _lastNode = editNodes[editNodes.length - 1];
        for (uint i = 0; i < editNodes.length; ++i)
        {
            Node@ _n = editNodes[i];
            Print(_n.name + " world-pos=" + _n.worldPosition.ToString() + " world-rot=" + _n.worldRotation.eulerAngles.ToString());
            Print("distance from " + _lastNode.name + " to " + _n.name " = " + (_n.worldPosition-_lastNode.worldPosition).length);
            _lastNode = _n;
        }
    }
    else if (input.keyPress[KEY_2])
    {
        AnimationState@ animState = GetEditingAnimationState();
        if (animState !is null)
        {
            animState.AddTime(-1.0f/30.0f);
            Print("Animation " + animState.animation.name + " current time " + animState.time);
        }
    }
    else if (input.keyPress[KEY_3])
    {
        AnimationState@ animState = GetEditingAnimationState();
        if (animState !is null)
        {
            animState.AddTime(1.0f/30.0f);
            Print("Animation " + animState.animation.name + " current time " + animState.time);
        }
    }
    else if (input.keyPress[KEY_4])
    {
        if (editNodes.empty)
            return;

        Node@ boneNode = editNodes[0];
        Node@ boxNode = null;
        float minDistSQR = 9999999;

        Array<Node@> nodes = editorScene.GetChildrenWithComponent("StaticModel");
        for (uint i=0; i<nodes.length; ++i)
        {
            Node@ _n = nodes[i];
            if (!_n.name.StartsWith("BOX"))
                continue;
            float distSQR = (_n.worldPosition - boneNode.worldPosition).lengthSquared;
            if (distSQR < minDistSQR)
            {
                boxNode = _n;
                minDistSQR = distSQR;
            }
        }

        if (boxNode is null)
            return;

        Vector3 p1, p2, p3, p4;
        float h = GetCorners(boxNode, p1, p2, p3, p4);
        Print("GetCorners --h=" + h);
        if (h <= 0)
            return;
        Array<float> distances;
        Vector3 pos = boneNode.worldPosition;
        distances.Push(GetDistance(p1, p2, pos));
        distances.Push(GetDistance(p2, p3, pos));
        distances.Push(GetDistance(p3, p4, pos));
        distances.Push(GetDistance(p4, p1, pos));

        float minDistance = 999999;
        uint minIndex = 999;
        for (uint i=0; i<distances.length; ++i)
        {
            if (distances[i] < minDistance)
            {
                minDistance = distances[i];
                minIndex = i;
            }
        }

        Ray ray;
        if (minIndex == 0)
            ray.Define(p1, p2 - p1);
        else if (minIndex == 1)
            ray.Define(p2, p3 - p2);
        else if (minIndex == 2)
            ray.Define(p3, p4 - p3);
        else if (minIndex == 3)
            ray.Define(p4, p1 - p4);

        Vector3 proj = ray.Project(pos);
        Vector3 offset = proj - pos;
        Print("LINE OFFSET = " + offset.ToString());
    }
}
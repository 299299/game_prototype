
float dragDistance = 0.0f;

void CreateDrag(float x, float y)
{
    Scene@ _scene = script.defaultScene;
    if (_scene is null)
        return;

    Node@ cameraNode = _scene.GetChild("Camera", true);
    Camera@ camera = cameraNode.GetComponent("Camera");
    Ray cameraRay = camera.GetScreenRay(x / graphics.width, y / graphics.height);
    float rayDistance = 100.0f;
    PhysicsRaycastResult result = _scene.physicsWorld.RaycastSingle(cameraRay, rayDistance, COLLISION_LAYER_RAGDOLL | COLLISION_LAYER_PROP);
    if (result.body !is null)
    {
        LogPrint("RaycastSingle Hit " + result.body.node.name + " distance=" + result.distance);
        Node@ draggingNode = _scene.CreateChild("DraggingNode");
        draggingNode.scale = Vector3(0.1f, 0.1f, 0.1f);
        StaticModel@ sphereObject = draggingNode.CreateComponent("StaticModel");
        sphereObject.model = cache.GetResource("Model", "Models/Sphere.mdl");
        sphereObject.material = cache.GetResource("Material", "Materials/BrightRedUnlit.xml");
        RigidBody@ body = draggingNode.CreateComponent("RigidBody");
        CollisionShape@ shape = draggingNode.CreateComponent("CollisionShape");
        shape.SetSphere(1);
        Constraint@ constraint = draggingNode.CreateComponent("Constraint");
        constraint.constraintType = CONSTRAINT_POINT;
        constraint.disableCollision = true;
        constraint.otherBody = result.body;
        dragDistance = result.distance;
        draggingNode.worldPosition = result.position;
    }
}

void DestroyDrag()
{
    Scene@ _scene = script.defaultScene;
    if (_scene is null)
        return;
    Node@ draggingNode = _scene.GetChild("DraggingNode", false);
    if (draggingNode !is null) {
        draggingNode.Remove();
        draggingNode = null;
    }
}

void MoveDrag(float x, float y)
{
    Scene@ _scene = script.defaultScene;
    if (_scene is null)
        return;
    Node@ draggingNode = _scene.GetChild("DraggingNode", false);
    if (draggingNode !is null) {
        Node@ cameraNode = _scene.GetChild("Camera", true);
        Camera@ camera = cameraNode.GetComponent("Camera");
        Vector3 v(float(x) / graphics.width, float(y) / graphics.height, dragDistance);
        draggingNode.worldPosition = camera.ScreenToWorldPoint(v);
    }
}

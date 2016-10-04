// ==============================================
//
//    Door Base Class
//
// ==============================================


class Door : Interactable
{
    AnimationController@    animCtrl;
    AnimatedModel@          animModel;
    Node@                   doorHandleNode;

    void ObjectStart()
    {
        Interactable::ObjectStart();

        RigidBody@ body = node.CreateComponent("RigidBody");
        body.collisionLayer = COLLISION_LAYER_PROP;
        body.collisionMask = COLLISION_LAYER_LANDSCAPE | COLLISION_LAYER_CHARACTER | COLLISION_LAYER_RAGDOLL | COLLISION_LAYER_RAYCAST | COLLISION_LAYER_PROP;
        CollisionShape@ shape = node.CreateComponent("CollisionShape");

        animModel = renderNode.GetComponent("AnimatedModel");
        animCtrl = renderNode.GetComponent("AnimationController");
        Model@ model = animModel.model;

        Vector3 offset = Vector3(renderNode !is null ? -animModel.boundingBox.halfSize.x : model.boundingBox.halfSize.x, model.boundingBox.halfSize.y, 0);
        shape.SetBox(model.boundingBox.size, offset);

        doorHandleNode = renderNode.GetChild("OB_SK_Handle", true);
    }

    Vector3 GetOverlayPoint()
    {
        return doorHandleNode.worldPosition;
    }
}

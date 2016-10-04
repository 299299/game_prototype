// ==============================================
//
//    Door Base Class
//
// ==============================================

class Door_OpeningState : Interactable_InteractivingState
{
    String animation_openning_1;
    String animation_openning_2;

    String animation_idle;

    int index;

    Door_OpeningState(Interactable@ i)
    {
        super(i);
        animation_openning_1 = GetAnimationName("AS_INTERACT_Door/A_GP_Interact_Door_YOpen_Door");
        animation_openning_2 = GetAnimationName("AS_INTERACT_Door/A_GP_Interact_Door_MinusYOpen_Door");
        animation_idle = GetAnimationName("AS_INTERACT_Door/A_GEN_Door_Posing");
    }

    void Enter(State@ lastState)
    {
        Interactable_InteractivingState::Enter(lastState);
        Player@ p = GetPlayer();
        Vector3 iDir = ownner.GetNode().worldRotation  * Vector3(0, 0, 1);
        float iAngle = Atan2(iDir.x, iDir.z);
        float angleDiff = Abs(AngleDiff(iAngle - p.GetCharacterAngle()));
        //Print("AngleDiff = " + angleDiff);
        index = (angleDiff < 90) ? 1 : 0;
        ownner.PlayAnimation((index == 0 ? animation_openning_1 : animation_openning_2), LAYER_MOVE, false);
        ownner.sceneNode.GetComponent("RigidBody").enabled = false;
    }

    void Exit(State@ nextState)
    {
        Interactable_InteractivingState::Exit(nextState);
        ownner.sceneNode.GetComponent("RigidBody").enabled = true;
    }

    void Update(float dt)
    {
        if (ownner.animCtrl.IsAtEnd((index == 0 ? animation_openning_1 : animation_openning_2)))
        {
            ownner.stateMachine.ChangeState("IdleState");
            ownner.PlayAnimation(animation_idle, LAYER_MOVE, true);
        }
        Interactable_InteractivingState::Update(dt);
    }
};


class Door : Interactable
{
    Node@                   doorHandleNode;
    Vector3                 povitPoint;

    void ObjectStart()
    {
        Interactable::ObjectStart();

        RigidBody@ body = sceneNode.CreateComponent("RigidBody");
        body.collisionLayer = COLLISION_LAYER_PROP;
        body.collisionMask = COLLISION_LAYER_LANDSCAPE | COLLISION_LAYER_CHARACTER | COLLISION_LAYER_RAGDOLL | COLLISION_LAYER_RAYCAST | COLLISION_LAYER_PROP;
        CollisionShape@ shape = sceneNode.CreateComponent("CollisionShape");

        Model@ model = animModel.model;

        Vector3 offset = Vector3(-animModel.boundingBox.halfSize.x, model.boundingBox.halfSize.y, 0);
        float scale = 1;
        shape.SetBox(model.boundingBox.size * scale, offset * scale);

        doorHandleNode = renderNode.GetChild("OB_SK_Handle", true);

        povitPoint = sceneNode.LocalToWorld(offset);
        type = kInteract_Door;

        collectText = "Door";
        interactText = "Door ... click to open";
    }

    void AddStates()
    {
        Interactable::AddStates();
        stateMachine.AddState(Door_OpeningState(this));
    }

    Vector3 GetOverlayPoint()
    {
        return doorHandleNode.worldPosition;
    }

    Vector3 GetPovitPoint()
    {
        return povitPoint;
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        debug.AddCross(povitPoint, 0.25f, GREEN, false);
        debug.AddNode(sceneNode, 0.5f, false);
    }
}

// ==============================================
//
//    Door Base Class
//
// ==============================================

class Door_IdleState : Interactable_IdleState
{
    String animation;

    Door_IdleState(Interactable@ i)
    {
        super(i);
        animation = GetAnimationName("AS_INTERACT_Door/A_GEN_Door_Posing");
    }

    void Enter(State@ lastState)
    {
        Interactable_IdleState::Enter(lastState);
        ownner.PlayAnimation(animation, LAYER_MOVE, true);
    }
};

class Door_OpeningState : Interactable_InteractivingState
{
    Array<String> animations;
    int index;

    Door_OpeningState(Interactable@ i)
    {
        super(i);
        animations.Push(GetAnimationName("AS_INTERACT_Door/A_GP_Interact_Door_YOpen_Door"));
        animations.Push(GetAnimationName("AS_INTERACT_Door/A_GP_Interact_Door_MinusYOpen_Door"));
    }

    void Enter(State@ lastState)
    {
        Interactable_InteractivingState::Enter(lastState);
        index = ownner.GetNode().vars[ANIMATION_INDEX].GetInt();
        ownner.PlayAnimation(animations[index], LAYER_MOVE, false);
        ownner.sceneNode.GetComponent("RigidBody").enabled = false;
    }

    void Exit(State@ nextState)
    {
        Interactable_InteractivingState::Exit(nextState);
        ownner.sceneNode.GetComponent("RigidBody").enabled = true;
    }

    void Update(float dt)
    {
        if (ownner.animCtrl.IsAtEnd(animations[index]))
        {
            ownner.stateMachine.ChangeState("IdleState");
            return;
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

        doorHandleNode = renderNode.GetChild("OB_SK_Handle", true);

        povitPoint = sceneNode.LocalToWorld(GetOffset());
        type = kInteract_Door;

        collectText = "Door";
        interactText = "Door ... click to open";
    }

    void AddStates()
    {
        stateMachine.AddState(Door_IdleState(this));
        stateMachine.AddState(Interactable_CollectableState(this));
        stateMachine.AddState(Interactable_InteractableState(this));
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

    Vector3 GetOffset()
    {
        return Vector3(-size.x/2.0f, size.y/2.0f, 0);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        debug.AddCross(povitPoint, 0.25f, GREEN, false);
        Interactable::DebugDraw(debug);
    }
}
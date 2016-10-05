// ==============================================
//
//    LightSource Base Class
//
// ==============================================

class LightSourceInteractivingState : Interactable_InteractivingState
{
    LightSourceInteractivingState(Interactable@ i)
    {
        super(i);
    }

    void Enter(State@ lastState)
    {
        cast<LightSource>(ownner).SwitchLight();
        Interactable_InteractivingState::Enter(lastState);
    }

    void Update(float dt)
    {
        if (timeInState > 1)
        {
            ownner.ChangeState("IdleState");
            return;
        }
        Interactable_InteractivingState::Update(dt);
    }
};


class LightSource : Interactable
{
    void ObjectStart()
    {
        Interactable::ObjectStart();

        type = kInteract_Light;
        collectText = FilterName(sceneNode.name);

        Node@ lightNode = sceneNode.GetChild("Light", true);
        if (lightNode !is null)
            interactText = collectText + "  ... click to switch";
    }

    void CreatePhysics()
    {
        RigidBody@ body = sceneNode.CreateComponent("RigidBody");
        body.collisionLayer = COLLISION_LAYER_PROP;
        body.collisionMask = COLLISION_LAYER_LANDSCAPE | COLLISION_LAYER_CHARACTER | COLLISION_LAYER_RAGDOLL | COLLISION_LAYER_RAYCAST | COLLISION_LAYER_PROP;
        CollisionShape@ shape = sceneNode.CreateComponent("CollisionShape");
        shape.SetBox(size, GetOffset());
    }

    void AddStates()
    {
        Interactable::AddStates();
        stateMachine.AddState(LightSourceInteractivingState(this));
    }

    void SwitchLight()
    {
        Node@ lightNode = sceneNode.GetChild("Light", true);
        if (lightNode is null)
            return;

        Light@ light = lightNode.GetComponent("Light");
        if (light is null)
            return;

        light.enabled = !light.enabled;
    }
}

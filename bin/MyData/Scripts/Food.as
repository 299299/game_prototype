// ==============================================
//
//    Food Base Class
//
// ==============================================

class FoodYummyState : Interactable_InteractivingState
{
    FoodYummyState(Interactable@ i)
    {
        super(i);
    }

    void Update(float dt)
    {
        if (timeInState > 2)
        {
            ownner.ChangeState("IdleState");
            return;
        }

        Interactable_InteractivingState::Update(dt);
    }
};


class Food : Interactable
{
    void ObjectStart()
    {
        Interactable::ObjectStart();

        type = kInteract_Food;
        collectText = FilterName(sceneNode.name);
        interactText = collectText + " yummy yummy ....";
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        debug.AddNode(sceneNode, 0.5f, false);
    }

    void CreatePhysics()
    {
        RigidBody@ body = sceneNode.CreateComponent("RigidBody");
        body.collisionLayer = COLLISION_LAYER_PROP;
        body.collisionMask = COLLISION_LAYER_LANDSCAPE | COLLISION_LAYER_CHARACTER | COLLISION_LAYER_RAGDOLL | COLLISION_LAYER_RAYCAST | COLLISION_LAYER_PROP;
        CollisionShape@ shape = sceneNode.CreateComponent("CollisionShape");
        if (sceneNode.name.Contains("bottle", false))
        {
            body.mass = 1;
            shape.SetCylinder(size.x, size.y, GetOffset());
        }
        else
        {
            shape.SetBox(size, GetOffset());
        }
    }

    void AddStates()
    {
        Interactable::AddStates();
        stateMachine.AddState(FoodYummyState(this));
    }
}

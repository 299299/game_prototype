// ==============================================
//
//    Interactable Base Class
//
// ==============================================


enum InteractType
{
    kInteract_None,
    kInteract_Door,
    kInteract_Food,
    kInteract_Funiture,
    kInteract_Vehicle,
    kInteract_Light,
    kInteract_Rubbish,
    kInteract_Accessory,
    kInteract_Decoration,
    kInteract_Nature,
};

String FilterName(const String&in name)
{
    Array<String> splits = name.Split('_');
    if (splits.length < 3)
        return name;
    String ret = splits[2];
    int pos = -1;
    for (int i=0; i<ret.length; ++i)
    {
        if (ret[i] == '0' || ret[i] == '1')
        {
            pos = i;
            break;
        }
    }

    if (pos > 0)
        ret = ret.Substring(0, pos);

    return ret;
}

class InteractableState : State
{
    Interactable@ ownner;

    InteractableState(Interactable@ i)
    {
        @ownner = i;
    }

    ~InteractableState()
    {
        @ownner = null;
    }
};

const float OPACITY_SPEED = 0.5f;

class Interactable_IdleState : InteractableState
{
    Interactable_IdleState(Interactable@ i)
    {
        super(i);
        SetName("IdleState");
    }

    void Enter(State@ lastState)
    {
        // ownner.overlayText.visible = false;
        State::Enter(lastState);
    }

    void Update(float dt)
    {
        float op = ownner.overlayText.opacity;
        if (ownner.overlayText.visible && op > 0.0f)
        {
            op -= OPACITY_SPEED * dt;
            if (op <= 0.0f)
            {
                ownner.overlayText.visible = false;
                ownner.overlayText.opacity = 0.0f;
            }
            else
                ownner.overlayText.opacity = op;
        }
        InteractableState::Update(dt);
    }
};


class Interactable_CollectableState : InteractableState
{
    Interactable_CollectableState(Interactable@ i)
    {
        super(i);
        SetName("CollectableState");
    }

    void Enter(State@ lastState)
    {
        ownner.overlayText.visible = true;
        ownner.overlayText.color = WHITE;
        ownner.overlayText.text = ownner.collectText;
        Vector2 v = gCameraMgr.GetCamera().WorldToScreenPoint(ownner.GetOverlayPoint());
        ownner.overlayText.position = IntVector2(v.x * graphics.width, v.y * graphics.height);
        State::Enter(lastState);
    }

    void Update(float dt)
    {
        if (ownner.overlayText.opacity < 1.0f)
        {
            float op = ownner.overlayText.opacity;
            op += OPACITY_SPEED * dt;
            ownner.overlayText.opacity = op;
        }
        InteractableState::Update(dt);
    }
};


class Interactable_InteractableState : InteractableState
{
    Interactable_InteractableState(Interactable@ i)
    {
        super(i);
        SetName("InteractableState");
    }

    void Enter(State@ lastState)
    {
        ownner.overlayText.visible = true;
        ownner.overlayText.color = YELLOW;
        ownner.overlayText.text = ownner.interactText;
        Vector2 v = gCameraMgr.GetCamera().WorldToScreenPoint(ownner.GetOverlayPoint());
        ownner.overlayText.position = IntVector2(v.x * graphics.width, v.y * graphics.height);
        State::Enter(lastState);
    }

    void Update(float dt)
    {
        if (ownner.overlayText.opacity < 1.0f)
        {
            float op = ownner.overlayText.opacity;
            op += OPACITY_SPEED * dt;
            ownner.overlayText.opacity = op;
        }
        InteractableState::Update(dt);
    }
};

class Interactable_InteractivingState : InteractableState
{
    Interactable_InteractivingState(Interactable@ i)
    {
        super(i);
        SetName("InteractivingState");
    }

    void Enter(State@ lastState)
    {
        ownner.overlayText.visible = false;
        ownner.overlayText.opacity = 0.0f;
        ownner.AddFlag(FLAGS_NO_COLLECTABLE);
        InteractableState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        ownner.RemoveFlag(FLAGS_NO_COLLECTABLE);
        InteractableState::Exit(nextState);
    }
};

class Interactable : GameObject
{
    Node@                   renderNode;
    Text@                   overlayText;
    FSM@                    stateMachine = FSM();

    AnimationController@    animCtrl;
    AnimatedModel@          animModel;
    StaticModel@            staticModel;

    int                     type;

    String                  collectText;
    String                  interactText;

    Vector3                 size;

    void AddStates()
    {
        stateMachine.AddState(Interactable_IdleState(this));
        stateMachine.AddState(Interactable_CollectableState(this));
        stateMachine.AddState(Interactable_InteractableState(this));
    }

    void ObjectStart()
    {
        GameObject::ObjectStart();

        renderNode = sceneNode.GetChild("RenderNode", false);

        if (renderNode !is null)
        {
            animModel = renderNode.GetComponent("AnimatedModel");
            animCtrl = renderNode.GetComponent("AnimationController");
            animModel.viewMask = VIEW_MASK_PROP;
            size = animModel.model.boundingBox.size;
        }
        else
        {
            staticModel = sceneNode.GetComponent("StaticModel");
            staticModel.viewMask = VIEW_MASK_PROP;
            size = staticModel.model.boundingBox.size;
        }

        overlayText = ui.root.CreateChild("Text", sceneNode.name + "_Overlay_Text");
        overlayText.SetFont(cache.GetResource("Font", UI_FONT), 15);
        overlayText.visible = false;
        overlayText.opacity = 0.0f;

        CreatePhysics();

        AddStates();
        stateMachine.ChangeState("IdleState");
    }

    void Stop()
    {
        @stateMachine = null;
        GameObject::Stop();
    }

    void ChangeState(const String&in name)
    {
        stateMachine.ChangeState(name);
    }

    Vector3 GetOverlayPoint()
    {
        return sceneNode.worldPosition + Vector3(0, size.y/2, 0);
    }

    Vector3 GetOffset()
    {
        return Vector3(0, size.y/2.0f, 0);
    }

    Vector3 GetPovitPoint()
    {
        return sceneNode.worldPosition + Vector3(0, size.y/2, 0);
    }

    void CreatePhysics()
    {
        RigidBody@ body = sceneNode.CreateComponent("RigidBody");
        body.collisionLayer = COLLISION_LAYER_PROP;
        body.collisionMask = COLLISION_LAYER_LANDSCAPE | COLLISION_LAYER_CHARACTER | COLLISION_LAYER_RAGDOLL | COLLISION_LAYER_RAYCAST | COLLISION_LAYER_PROP;
        CollisionShape@ shape = sceneNode.CreateComponent("CollisionShape");
        shape.SetBox(size, GetOffset());
    }

    int DoInteract()
    {
        Print(GetName() + " DoInteract");
        stateMachine.ChangeState("InteractivingState");
        return 0;
    }

    void Update(float dt)
    {
        stateMachine.Update(dt);
        GameObject::Update(dt);
    }

    void PlayAnimation(const String&in animName, uint layer = LAYER_MOVE, bool loop = false, float blendTime = 0.2f, float startTime = 0.0f, float speed = 1.0f)
    {
        if (d_log)
            Print(GetName() + " PlayAnimation " + animName + " loop=" + loop + " blendTime=" + blendTime + " startTime=" + startTime + " speed=" + speed);

        AnimationController@ ctrl = animCtrl;
        ctrl.StopLayer(layer, blendTime);
        ctrl.PlayExclusive(animName, layer, loop, blendTime);
        ctrl.SetSpeed(animName, speed * timeScale);
        ctrl.SetTime(animName, (speed < 0) ? ctrl.GetLength(animName) : startTime);
    }


    void DebugDraw(DebugRenderer@ debug)
    {
        debug.AddNode(sceneNode, 0.5f, false);
    }
}
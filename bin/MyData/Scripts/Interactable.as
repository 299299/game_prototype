// ==============================================
//
//    Interactable Base Class
//
// ==============================================


enum InteractType
{
    kInteract_None,
    kInteract_Door,
};

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


class Interactable_IdleState : InteractableState
{
    Interactable_IdleState(Interactable@ i)
    {
        super(i);
        SetName("IdleState");
    }

    void Enter(State@ lastState)
    {
        ownner.overlayText.visible = false;
        State::Enter(lastState);
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

    int                     type;

    String                  collectText;
    String                  interactText;

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
        }

        overlayText = ui.root.CreateChild("Text", sceneNode.name + "_Overlay_Text");
        overlayText.SetFont(cache.GetResource("Font", UI_FONT), 15);
        overlayText.visible = false;
        AddStates();
        stateMachine.ChangeState("IdleState");
    }

    void ChangeState(const String&in name)
    {
        stateMachine.ChangeState(name);
    }

    Vector3 GetOverlayPoint()
    {
        return sceneNode.worldPosition;
    }



    void Stop()
    {
        @stateMachine = null;
        GameObject::Stop();
    }

    Vector3 GetPovitPoint()
    {
        return sceneNode.worldPosition;
    }

    void DoInteract()
    {
        Print(GetName() + " DoInteract");
        stateMachine.ChangeState("InteractivingState");
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
}
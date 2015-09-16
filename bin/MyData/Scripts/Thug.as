
class ThugStandState : CharacterState
{
    Array<String>           animations;

    ThugStandState(Character@ c)
    {
        super(c);
        name = "StandState";
        animations.Push(GetAnimationName("BM_Combat_Movement/Stand_Idle"));
    }

    void Enter(State@ lastState)
    {
        PlayAnimation(ownner.animCtrl, animations[RandomInt(animations.length)], LAYER_MOVE, true, 0.25f);
    }

    void Update(float dt)
    {
        CharacterState::Update(dt);
    }
};

class ThugCounterState : MultiMotionState
{
    ThugCounterState(Character@ c)
    {
        super(c);
        name = "CounterState";
        // motions.Push(gMotionMgr.FindMotion("TG_BM_Counter/Counter_Arm_Front_01"));
    }

    void Update(float dt)
    {
        if (motions[selectIndex].Move(dt, ownner.sceneNode, ownner.animCtrl))
            ownner.stateMachine.ChangeState("StandState");

        CharacterState::Update(dt);
    }

    int PickIndex()
    {
        return ownner.sceneNode.vars["CounterIndex"].GetInt();
    }
};


class ThugAlignState : CharacterAlignState
{
    ThugAlignState(Character@ c)
    {
        super(c);
    }
};

class ThugAttackState : MultiMotionState
{
    ThugAttackState(Character@ c)
    {
        super(c);
        name = "CounterState";
    }

    void Update(float dt)
    {
        if (motions[selectIndex].Move(dt, ownner.sceneNode, ownner.animCtrl))
            ownner.stateMachine.ChangeState("StandState");

        CharacterState::Update(dt);
    }

    int PickIndex()
    {
        return ownner.sceneNode.vars["AttackIndex"].GetInt();
    }
};

class ThugHitState : MultiMotionState
{
    ThugHitState(Character@ c)
    {
        super(c);
        name = "CounterState";
    }

    void Update(float dt)
    {
        if (motions[selectIndex].Move(dt, ownner.sceneNode, ownner.animCtrl))
            ownner.stateMachine.ChangeState("StandState");

        CharacterState::Update(dt);
    }

    int PickIndex()
    {
        return ownner.sceneNode.vars["Hit"].GetInt();
    }
};


class Thug : Enemy
{
    void Start()
    {
        Enemy::Start();
        stateMachine.AddState(ThugStandState(this));
        stateMachine.AddState(ThugCounterState(this));
        stateMachine.AddState(ThugAlignState(this));
        stateMachine.AddState(ThugHitState(this));
        stateMachine.ChangeState("StandState");
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        Character::DebugDraw(debug);
    }
};


#include "Scripts/Test/Enemy.as"

class ThugStandState : CharacterState
{
    Array<String>           animations;

    ThugStandState(Character@ c)
    {
        super(c);
        name = "StandState";
        animations.Push("Animation/Stand_Idle.ani");
        //animations.Push("Animation/Stand_Idle_01.ani");
        //animations.Push("Animation/Stand_Idle_02.ani");
    }

    void Enter(State@ lastState)
    {
        PlayAnimation(ownner.animCtrl, animations[RandomInt(animations.length)], LAYER_MOVE, true, 0.25f);
    }

    void Update(float dt)
    {

    }
};

class ThugCounterState : MultiMotionState
{
    ThugCounterState(Character@ c)
    {
        super(c);
        name = "CounterState";
        motions.Push(Motion("Animation/Counter_Arm_Front_01_TG.ani", 0, -1, false, false));
    }

    void Update(float dt)
    {
        if (motions[selectIndex].Move(dt, ownner.sceneNode, ownner.animCtrl))
            ownner.stateMachine.ChangeState("StandState");
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

class Thug : Enemy
{
    void Start()
    {
        Enemy::Start();
        stateMachine.AddState(ThugStandState(this));
        stateMachine.AddState(ThugCounterState(this));
        stateMachine.AddState(ThugAlignState(this));
        stateMachine.ChangeState("StandState");
    }


    void Update(float dt)
    {
        Character::Update(dt);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        debug.AddNode(this.sceneNode, 1.0f, false);
        debug.AddNode(this.sceneNode.GetChild("Bip01", true), 1.0f, false);
    }
};


#include "Scripts/Test/Character.as"

class EnemyStandState : CharacterState
{
    Array<String>           animations;

    EnemyStandState(Node@ n, Character@ c)
    {
        super(n, c);
        name = "StandState";
        animations.Push("Animation/Stand_Idle.ani");
        animations.Push("Animation/Stand_Idle_01.ani");
        animations.Push("Animation/Stand_Idle_02.ani");
    }

    void Enter(State@ lastState)
    {
        float blendTime = 0.5f;
        if (lastState !is null && lastState.name == "MoveState")
            blendTime = 0.25f;
        PlayAnimation(ctrl, animations[RandomInt(animations.length)], LAYER_MOVE, true, blendTime);
    }

    void Update(float dt)
    {

    }
};


class Enemy : Character
{
    void Start()
    {

    }

    void Update(float dt)
    {
        Character::Update(dt);
    }

    void DebugDraw(DebugRenderer@ debug)
    {

    }
};

class EnemyManager
{
    EnemyManager()
    {
        Print("EnemyManager()");
    }

    ~EnemyManager()
    {
        Print("~EnemyManager()");
    }

    Node@ CreateEnemy()
    {
        return null;
    }
};
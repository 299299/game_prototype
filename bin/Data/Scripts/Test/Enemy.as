#include "Scripts/Test/Character.as"

class EnemyStandState : CharacterState
{
    Array<String>           animations;

    EnemyStandState(Character@ c)
    {
        super(c);
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
        PlayAnimation(ownner.animCtrl, animations[RandomInt(animations.length)], LAYER_MOVE, true, blendTime);
    }

    void Update(float dt)
    {

    }
};


class Enemy : Character
{
    void Start()
    {
        Character::Start();
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
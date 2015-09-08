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
        gEnemyMgr.RegisterEnemy(this);
    }

    void Stop()
    {
        Character::Stop();
        gEnemyMgr.UnRegisterEnemy(this);
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
        numMaxAttackers = 2;
    }

    ~EnemyManager()
    {
        Print("~EnemyManager()");
    }

    Node@ CreateEnemy()
    {
        return null;
    }

    void RegisterEnemy(Enemy@ e)
    {
        enemyList.Push(e);
    }

    void UnRegisterEnemy(Enemy@ e)
    {
        UnRegisterAttacker(e);
        int i = enemyList.FindByRef(e);
        if (i < 0)
            return;
        enemyList.Erase(i);
    }

    bool RegisterAttacker(Enemy@ e)
    {
        if (attackerList.length >= numMaxAttackers)
            return false;
        int index = attackerList.FindByRef(e);
        if (index != -1) {
            Print("Enemy " + e.sceneNode.name + " already in attack list.");
            return false;
        }
        attackerList.Push(e);
        return true;
    }

    void UnRegisterAttacker(Enemy@ e)
    {
        int i = attackerList.FindByRef(e);
        if (i < 0)
            return;
        attackerList.Erase(i);
    }

    Array<Enemy@>             enemyList;
    Array<Enemy@>             attackerList;
    int                       numMaxAttackers;

    Array<float>              distacneCache;
    Array<float>              directionCache;
    Array<int>                scoreCache;
};

EnemyManager@ gEnemyMgr;
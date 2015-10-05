

class Enemy : Character
{
    Character@          target;
    float               targetDistance;

    void Start()
    {
        Character::Start();
        gEnemyMgr.RegisterEnemy(this);
    }

    void Stop()
    {
        @target = null;
        Character::Stop();
        gEnemyMgr.UnRegisterEnemy(this);
    }

    void Update(float dt)
    {
        targetDistance = GetTargetDistance();
        Character::Update(dt);
    }

    void DebugDraw(DebugRenderer@ debug)
    {

    }

    float GetTargetAngle()
    {
        return GetTargetAngle(target.sceneNode);
    }

    float GetTargetDistance()
    {
        return GetTargetDistance(target.sceneNode);
    }

    bool CanBeCountered()
    {
        return IsInState("AttackState");
    }

    bool CanBeRedirected()
    {
        return IsInState("StandState") || IsInState("TurnState");
    }

    String GetDebugText()
    {
        return Character::GetDebugText() +  "distToPlayer=" + targetDistance + "\n";
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

    void RegisterEnemy(Enemy@ e)
    {
        enemyList.Push(e);
    }

    void UnRegisterEnemy(Enemy@ e)
    {
        int i = enemyList.FindByRef(e);
        if (i < 0)
            return;
        enemyList.Erase(i);
    }

    int GetNumOfEnemyInState(const StringHash&in nameHash)
    {
        int ret = 0;
        for (uint i=0; i<enemyList.length; ++i)
        {
            if (enemyList[i].IsInState(nameHash))
                ++ret;
        }
        return ret;
    }

    Array<Enemy@>             enemyList;
    Array<int>                scoreCache;
};

EnemyManager@ gEnemyMgr = EnemyManager();
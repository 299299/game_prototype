

class Enemy : Character
{
    Character@          target;

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

    bool CanBeAttacked()
    {
        return HasFlag(FLAGS_ATTACK);
    }

    bool CanBeCountered()
    {
        return HasFlag(FLAGS_COUNTER);
    }

    bool CanBeRedirected()
    {
        return HasFlag(FLAGS_REDIRECTED);
    }

    String GetDebugText()
    {
        return Character::GetDebugText() +  "flags=" + flags + " distToPlayer=" + GetTargetDistance() + "\n";
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
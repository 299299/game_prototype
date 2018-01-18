// ==============================================
//
//    Enemy Base Class and EnemyManager Class
//
// ==============================================

class Enemy : Character
{
    void ObjectStart()
    {
        Character::ObjectStart();
        EnemyManager@ em = GetEnemyMgr();
        if (em !is null)
            em.RegisterEnemy(this);
        SetTarget(GetPlayer());
    }

    void Remove()
    {
        EnemyManager@ em = GetEnemyMgr();
        if (em !is null)
            em.UnRegisterEnemy(this);
        Character::Remove();
    }

    String GetDebugText()
    {
        return Character::GetDebugText() + "health=" + health +  " flags=" + flags + " distToPlayer=" + GetTargetDistance() + " timeScale=" + timeScale + "\n";
    }

    bool KeepDistanceWithEnemy()
    {
        return false;
    }

    bool KeepDistanceWithPlayer(float max_dist)
    {
        return false;
    }
};

class EnemyManager : ScriptObject
{
    Array<Vector3>      enemyResetPositions;
    Array<Quaternion>   enemyResetRotations;
    Array<Enemy@>       enemyList;

    int                 thugId = 0;
    float               updateTimer = 0.0f;
    float               updateTime = 0.25f;

    float               attackValidDist = 6.0f;

    EnemyManager()
    {
        LogPrint("EnemyManager()");
    }

    ~EnemyManager()
    {
        LogPrint("~EnemyManager()");
    }

    void Start()
    {
        LogPrint("EnemyManager::Start()");
    }

    void Stop()
    {
        LogPrint("EnemyManager::Stop()");
        enemyList.Clear();
    }

    Node@ CreateEnemy(const Vector3&in position, const Quaternion&in rotation, const String&in type, const String&in name = "")
    {
        if (type == "thug")
            return CreateThug(name, position, rotation);
        return null;
    }

    void RegisterEnemy(Enemy@ e)
    {
        enemyList.Push(e);
    }

    void UnRegisterEnemy(Enemy@ e)
    {
        LogPrint("UnRegisterEnemy " + e.GetName());
        int i = enemyList.FindByRef(e);
        if (i < 0)
            return;
        enemyList.Erase(i);
    }

    int GetNumOfEnemyAttackValid()
    {
        int ret = 0;
        for (uint i=0; i<enemyList.length; ++i)
        {
            Enemy@ e = enemyList[i];
            if (e.IsInState(ATTACK_STATE) && e.GetTargetDistance(e.target.GetNode().worldPosition) < attackValidDist)
                ++ret;
        }
        return ret;
    }

    int GetNumOfEnemyHasFlag(int flag)
    {
        int ret = 0;
        for (uint i=0; i<enemyList.length; ++i)
        {
            if (enemyList[i].HasFlag(flag))
                ++ret;
        }
        return ret;
    }

    int GetNumOfEnemyAlive()
    {
        int ret = 0;
        for (uint i=0; i<enemyList.length; ++i)
        {
            if (enemyList[i].health != 0)
                ++ret;
        }
        return ret;
    }

    int GetNumOfEnemyWithinDistance(float dist)
    {
        int ret = 0;
        for (uint i=0; i<enemyList.length; ++i)
        {
            Enemy@ e = enemyList[i];
            if (enemyList[i].GetTargetDistance(e.target.GetNode().worldPosition) < dist)
                ++ret;
        }
        return ret;
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        if (enemyList.empty)
            return;
        // Character@ player = enemyList[0].target;
        // Vector3 v1 = player.GetNode().worldPosition;
        for (uint i=0; i<enemyList.length; ++i)
        {
            enemyList[i].DebugDraw(debug);
            // debug.AddLine(v1, enemyList[i].GetNode().worldPosition, Color(0.25f, 0.55f, 0.65f), false);
        }
    }

    Node@ CreateThug(const String&in name, const Vector3&in position, const Quaternion& rotation)
    {
        String thugName = name;
        if (thugName == "")
            thugName = "thug_" + thugId;
        thugId ++;
        Node@ node = CreateCharacter(thugName, "mt", "Thug", position, rotation);
        node.AddTag(ENEMY_TAG);
        return node;
    }

    void RemoveAll()
    {
        for (uint i=0; i<enemyList.length; ++i)
        {
            enemyList[i].GetNode().Remove();
        }
        enemyList.Clear();
        Reset();
    }

    void Reset()
    {
        thugId = 0;
    }

    void CreateEnemies()
    {
        for (uint i=0; i<enemyResetPositions.length; ++i)
        {
            CreateEnemy(enemyResetPositions[i], enemyResetRotations[i], "thug");
        }
    }

    void Update(float dt)
    {
        updateTimer += dt;
        if (updateTimer >= updateTime)
        {
            DoUpdate();
            updateTimer -= updateTime;
        }
    }

    void DoUpdate()
    {
        int num_of_near = 0;
        for (uint i=0; i<enemyList.length; ++i)
        {
            Enemy@ e = enemyList[i];
            float dis = e.GetTargetDistance(e.target.GetNode().worldPosition);
            if (dis <= AI_NEAR_DIST)
                num_of_near ++;
            if (num_of_near > MAX_NUM_OF_NEAR)
            {
                e.KeepDistanceWithPlayer(AI_NEAR_DIST);
            }
        }
    }

    Vector3 FindTargetPosition(Enemy@ self, float radius)
    {
        Scene@ scene_ = script.defaultScene;
        CrowdManager@ crowdManager = scene_.GetComponent("CrowdManager");
        if (crowdManager is null)
            return Vector3();
        Player@ p = GetPlayer();
        if (p is null)
            return Vector3();
        return crowdManager.GetRandomPointInCircle(p.GetNode().worldPosition, self.agent.radius, self.agent.queryFilterType);
    }

    void SendEvent(const String&in eventName, VariantMap& eventData)
    {
        for (uint i=0; i<enemyList.length; ++i)
        {
            enemyList[i].SendEvent(eventName, eventData);
        }
    }
};
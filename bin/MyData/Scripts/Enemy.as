// ==============================================
//
//    Enemy Base Class and EnemyManager Class
//
// ==============================================

class Enemy : Character
{
    int zoneToPlayer = -1;
    int targetZoneToPlayer = -1;

    void ObjectStart()
    {
        Character::ObjectStart();
        EnemyManager@ em = cast<EnemyManager>(scene.GetScriptObject("EnemyManager"));
        if (em !is null)
            em.RegisterEnemy(this);
        SetTarget(GetPlayer());
    }

    void Remove()
    {
        EnemyManager@ em = cast<EnemyManager>(scene.GetScriptObject("EnemyManager"));
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

    bool KeepDistanceWithPlayer(float max_dist = KEEP_DIST_WITH_PLAYER)
    {
        return false;
    }

    void UpdateZone()
    {
        zoneToPlayer = GetDirectionZone(target.GetNode().worldPosition, sceneNode.worldPosition, NUM_ZONE_DIRECTIONS);
        // Print(GetName() + " zoneToPlayer = " + zoneToPlayer);
    }
};

class EnemyManager : ScriptObject
{
    Array<Vector3>      enemyResetPositions;
    Array<Quaternion>   enemyResetRotations;

    Array<Enemy@>       enemyList;
    Array<int>          scoreCache;

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
        LogPrint("UnRegisterEnemy");
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
            if (e.IsInState(ATTACK_STATE) && e.GetTargetDistance() < attackValidDist)
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
            if (enemyList[i].GetTargetDistance() < dist)
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
        Node@ node = CreateCharacter(thugName, "thug", "Thug", position, rotation);
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
            e.UpdateZone();
            float dis = e.GetTargetDistance();
            if (dis <= AI_NEAR_DIST)
                num_of_near ++;
            if (num_of_near > MAX_NUM_OF_NEAR)
            {
                // LogPrint(e.GetName() + " too close with player !!!");
                if (e.GetState().nameHash == STAND_STATE || e.GetState().nameHash == TURN_STATE)
                    e.KeepDistanceWithPlayer(0);
            }
        }
    }

    Vector3 FindGoodTargetPosition(Enemy@ self, float radius)
    {
        for (uint i=0; i<zoneDirCache.length; ++i)
            zoneDirCache[i] = 0;

        for (uint i=0; i<enemyList.length; ++i)
        {
            Enemy@ e = enemyList[i];
            if (e is self)
                continue;

            if (e.zoneToPlayer >= 0)
                zoneDirCache[e.zoneToPlayer] = zoneDirCache[e.zoneToPlayer] + 1;
            if (e.targetZoneToPlayer >= 0)
                zoneDirCache[e.targetZoneToPlayer] = zoneDirCache[e.targetZoneToPlayer] + 1;
        }

        uint least_num = enemyList.length + 1;
        int best_dir = -1;
        for (uint i=0; i<4; ++i)
        {
            if (zoneDirCache[i] < least_num)
            {
                best_dir = int(i);
                least_num = zoneDirCache[i];
            }
        }

        float zone_degree = 360 / NUM_ZONE_DIRECTIONS;
        float degree_min = best_dir * zone_degree - zone_degree/2 - 10;
        float degree_max = best_dir * zone_degree + zone_degree/2 - 10;
        float degree = Random(degree_min, degree_max);
        Vector3 v(radius * Sin(degree), 0, radius * Cos(degree));
        v += self.target.GetNode().worldPosition;
        Print(self.GetName() + " FindGoodTargetPosition best_dir=" + best_dir + " degree=" + degree + " v=" + v.ToString());
        return v;
    }
};
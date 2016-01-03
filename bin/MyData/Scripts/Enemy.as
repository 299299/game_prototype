// ==============================================
//
//    Enemy Base Class and EnemyManager Class
//
// ==============================================

class Enemy : Character
{
    float requiredDistanceFromNeighbors = 1.25f;

    void Start()
    {
        Character::Start();
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

    void DebugDraw(DebugRenderer@ debug)
    {

    }

    float GetTargetAngle()
    {
        if (target is null)
            return 0;
        return GetTargetAngle(target.sceneNode);
    }

    float GetTargetDistance()
    {
        if (target is null)
            return 0;
        return GetTargetDistance(target.sceneNode);
    }

    String GetDebugText()
    {
        return Character::GetDebugText() + "health=" + health +  " flags=" + flags + " distToPlayer=" + GetTargetDistance() + " timeScale=" + timeScale + "\n";
    }

    bool IsTargetSightBlocked()
    {
        Vector3 my_mid_pos = sceneNode.worldPosition;
        my_mid_pos.y += CHARACTER_HEIGHT/2;
        Vector3 target_mid_pos = target.sceneNode.worldPosition;
        target_mid_pos.y += CHARACTER_HEIGHT/2;
        Vector3 dir = target_mid_pos - my_mid_pos;
        float rayDistance = dir.length;
        Ray sightRay;
        sightRay.origin = my_mid_pos;
        sightRay.direction = dir.Normalized();
        PhysicsRaycastResult result = sceneNode.scene.physicsWorld.RaycastSingle(sightRay, rayDistance, COLLISION_LAYER_CHARACTER);
        if (result.body is null)
            return false;
        return true;
    }
};

class EnemyManager : ScriptObject
{
    Array<Vector3>      enemyResetPositions;
    Array<Quaternion>   enemyResetRotations;

    int thugId = 0;

    EnemyManager()
    {
        Print("EnemyManager()");
    }

    ~EnemyManager()
    {
        Print("~EnemyManager()");
    }

    void Start()
    {
        Print("EnemyManager::Start()");
    }

    void Stop()
    {
        Print("EnemyManager::Stop()");
        enemyList.Clear();
    }

    Node@ CreateEnemy(const Vector3&in position, const Quaternion&in rotation, const String&in type, const String&in name = "")
    {
        if (type == "Thug")
            return CreateThug(name, position, rotation);
        return null;
    }

    void RegisterEnemy(Enemy@ e)
    {
        enemyList.Push(e);
    }

    void UnRegisterEnemy(Enemy@ e)
    {
        Print("UnRegisterEnemy");
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
            thugName = "Thug_" + thugId;
        thugId ++;
        return CreateCharacter(thugName, "thug", "Thug", position, rotation);
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
            CreateEnemy(enemyResetPositions[i], enemyResetRotations[i], "Thug");
        }
    }

    Array<Enemy@>             enemyList;
    Array<int>                scoreCache;
};
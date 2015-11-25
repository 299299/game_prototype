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
        @target = cast<Character@>(scene.GetChild("player", false).scriptObject);
        EnemyManager@ em = cast<EnemyManager>(scene.GetScriptObject("EnemyManager"));
        if (em !is null)
            em.RegisterEnemy(this);
    }

    void Stop()
    {
        Character::Stop();

        EnemyManager@ em = cast<EnemyManager>(scene.GetScriptObject("EnemyManager"));
        if (em !is null)
            em.UnRegisterEnemy(this);
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
    int thugId = 0;
    Scene@ gameScene;

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
        gameScene = scene;
    }

    void Stop()
    {
        enemyList.Clear();
        gameScene = null;
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
        for (uint i=0; i<enemyList.length; ++i)
            enemyList[i].DebugDraw(debug);
    }

    Node@ CreateThug(const String&in name, const Vector3&in position, const Quaternion& rotation)
    {
        String thugName = name;
        if (thugName == "")
            thugName = "Thug_" + thugId;
        thugId ++;
        XMLFile@ xml = cache.GetResource("XMLFile", "Objects/thug.xml");
        Node@ thugNode = gameScene.InstantiateXML(xml, position, rotation);
        thugNode.name = thugName;
        thugNode.CreateScriptObject(scriptFile, "Thug");
        thugNode.CreateScriptObject(scriptFile, "Ragdoll");
        return thugNode;
    }

    void RemoveAll()
    {
        for (uint i=0; i<enemyList.length; ++i)
        {
            enemyList[i].GetNode().Remove();
        }
        enemyList.Clear();
    }

    Array<Enemy@>             enemyList;
    Array<int>                scoreCache;
};
// ==============================================
//
//    Enemy Base Class and EnemyManager Class
//
// ==============================================

class Enemy : Character
{
    void Start()
    {
        Character::Start();
        @target = cast<Character@>(scene.GetChild("player", false).GetScriptObject("Player"));
        EnemyManager@ em = cast<EnemyManager@>(sceneNode.scene.GetScriptObject("EnemyManager"));
        if (em !is null)
            em.RegisterEnemy(this);
    }

    void Stop()
    {
        Character::Stop();

        EnemyManager@ em = cast<EnemyManager@>(sceneNode.scene.GetScriptObject("EnemyManager"));
        if (em !is null)
            em.UnRegisterEnemy(this);
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

    String GetDebugText()
    {
        return Character::GetDebugText() +  "flags=" + flags + " distToPlayer=" + GetTargetDistance() + " timeScale=" + timeScale + "\n";
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
        thugNode.name = name;
        thugNode.CreateScriptObject(scriptFile, "Thug");
        thugNode.CreateScriptObject(scriptFile, "Ragdoll");
        return thugNode;
    }

    Array<Enemy@>             enemyList;
    Array<int>                scoreCache;
};
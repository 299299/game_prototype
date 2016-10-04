// ==============================================
//
//    GameObject Base Class
//
// ==============================================

class GameObject : ScriptObject
{
    Node@   sceneNode;
    float   duration = -1;
    int     flags = 0;
    int     side = 0;
    float   timeScale = 1.0f;

    void ObjectStart()
    {
        @sceneNode = node;
    }

    void DelayedStart()
    {
        ObjectStart();
    }

    void Stop()
    {
        @sceneNode = null;
    }

    void SetTimeScale(float scale)
    {
        timeScale = scale;
        Print(GetName() + " SetTimeScale:" + scale);
    }

    void FixedUpdate(float timeStep)
    {
        timeStep *= timeScale;
        CheckDuration(timeStep);
    }

    void CheckDuration(float timeStep)
    {
        // Disappear when duration expired
        if (duration >= 0)
        {
            duration -= timeStep;
            if (duration <= 0)
                Remove();
        }
    }

    void Update(float timeStep)
    {
        timeStep *= timeScale;
    }

    void PlaySound(const String&in soundName)
    {
        // Create the sound channel
        SoundSource3D@ source = GetNode().CreateComponent("SoundSource3D");
        //SoundSource@ source = GetNode().CreateComponent("SoundSource");
        Sound@ sound = cache.GetResource("Sound", soundName);
        source.SetDistanceAttenuation(5, 50, 2);
        source.Play(sound);
        source.soundType = SOUND_EFFECT;
        source.frequency = source.frequency * GetNode().scene.timeScale; // * timeScale;
        // Subscribe to sound finished for cleaning up the source
        SubscribeToEvent(node, "SoundFinished", "HandleSoundFinished");
    }

    void HandleSoundFinished(StringHash eventType, VariantMap& eventData)
    {
        SoundSource3D@ source = eventData["SoundSource"].GetPtr();
        source.Remove();
    }

    void DebugDraw(DebugRenderer@ debug)
    {

    }

    String GetDebugText()
    {
        return "";
    }

    String GetName()
    {
        return "";
    }

    void AddFlag(int flag)
    {
        flags |= flag;
    }

    void RemoveFlag(int flag)
    {
        flags &= ~flag;
    }

    bool HasFlag(int flag)
    {
        return flags & flag != 0;
    }

    void Reset()
    {

    }

    bool OnDamage(GameObject@ attacker, const Vector3&in position, const Vector3&in direction, int damage, bool weak = false)
    {
        return true;
    }

    Node@ GetNode()
    {
        return sceneNode;
    }

    Scene@ GetScene()
    {
        Node@ _node = GetNode();
        if (_node is null)
            return null;
        return _node.scene;
    }

    void SetSceneTimeScale(float scale)
    {
        Scene@ _scene = GetScene();
        if (_scene is null)
            return;
        if (_scene.timeScale == scale)
            return;
        _scene.timeScale = scale;
        gGame.OnSceneTimeScaleUpdated(_scene, scale);
        Print(GetName() + " SetSceneTimeScale:" + scale);
    }

    void Transform(const Vector3& pos, const Quaternion& qua)
    {
        Node@ _node = GetNode();
        _node.worldPosition = pos;
        _node.worldRotation = qua;
    }

    void Remove()
    {
        // Print(node.name + ".Remove()");
        node.Remove();
    }

    bool IsVisible()
    {
        return true;
    }
};

void SetWorldTimeScale(Scene@ _scene, float scale)
{
    Print("SetWorldTimeScale:" + scale);
    Array<Node@> nodes = _scene.GetChildrenWithScript(false);
    for (uint i=0; i<nodes.length; ++i)
    {
        GameObject@ object = cast<GameObject>(nodes[i].scriptObject);
        if (object is null)
            continue;
        object.SetTimeScale(scale);
    }
}
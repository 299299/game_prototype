// ==============================================
//
//    GameObject Base Class
//
// ==============================================

const int CTRL_ATTACK = (1 << 0);
const int CTRL_JUMP = (1 << 1);
const int CTRL_ALL = (1 << 16);

const int FLAGS_ATTACK  = (1 << 0);
const int FLAGS_COUNTER = (1 << 1);
const int FLAGS_REDIRECTED = (1 << 2);
const int FLAGS_NO_MOVE = (1 << 3);

const int COLLISION_LAYER_CHARACTER = (1 << 0);
const int COLLISION_LAYER_LANDSCAPE = (1 << 1);
const int COLLISION_LAYER_PROP      = (1 << 2);
const int COLLISION_LAYER_RAGDOLL   = (1 << 3);
const int COLLISION_LAYER_ATTACK    = (1 << 4);

class GameObject : ScriptObject
{
    FSM@    stateMachine = FSM();
    float   duration = -1;
    int     flags = 0;
    float   timeScale = 1.0f;

    GameObject()
    {

    }

    void Start()
    {

    }

    void Stop()
    {
        @stateMachine = null;
    }

    void SetTimeScale(float scale)
    {
        timeScale = scale;
    }

    void FixedUpdate(float timeStep)
    {
        timeStep *= timeScale;
        stateMachine.FixedUpdate(timeStep);
        // Disappear when duration expired
        if (duration >= 0)
        {
            duration -= timeStep;
            if (duration <= 0)
                node.Remove();
        }
    }

    void Update(float timeStep)
    {
        timeStep *= timeScale;
        stateMachine.Update(timeStep);
    }

    void PlaySound(const String&in soundName, float freqScale = 1.0f)
    {
        // Create the sound channel
        SoundSource3D@ source = node.CreateComponent("SoundSource3D");
        Sound@ sound = cache.GetResource("Sound", soundName);

        source.SetDistanceAttenuation(1, 100, 2);
        source.Play(sound);
        source.autoRemove = true;
        source.soundType = SOUND_EFFECT;
        source.frequency = source.frequency * freqScale;
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        stateMachine.DebugDraw(debug);
    }

    String GetDebugText()
    {
        return stateMachine.GetDebugText();
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

    State@ GetState()
    {
        return stateMachine.currentState;
    }

    bool IsInState(const String&in name)
    {
        return IsInState(StringHash(name));
    }

    bool IsInState(const StringHash&in nameHash)
    {
        State@ state = stateMachine.currentState;
        if (state is null)
            return false;
        return state.nameHash == nameHash;
    }

    void OnDamage(GameObject@ attacker, const Vector3&in position, const Vector3&in direction, int damage, bool weak = false)
    {

    }

    Node@ GetNode()
    {
        return null;
    }

    void ChangeState(const String&in state)
    {
        stateMachine.ChangeState(state);
    }
};


void AddDebugMark(DebugRenderer@ debug, const Vector3&in position, const Color&in color, float size=0.15f)
{
    Sphere sp;
    sp.Define(position, size);
    debug.AddSphere(sp, color, false);
}

void SetWorldTimeScale(Scene@ _scene, float scale)
{
    Array<Node@> nodes = _scene.GetChildrenWithScript(false);
    for (uint i=0; i<nodes.length; ++i)
    {
        GameObject@ object = cast<GameObject@>(nodes[i].scriptObject);
        if (object is null)
            continue;
        object.SetTimeScale(scale);
    }
}
/*           ==============       ==============
            |               |____|               |
            \               /    \               /
              =============        ==============
                             ●   ●                        */

// ------------------------------------------------
#include "Scripts/Variables.as"
#include "Scripts/Game.as"
#include "Scripts/AssetProcess.as"
#include "Scripts/Motion.as"
#include "Scripts/PhysicsDrag.as"
#include "Scripts/Input.as"
#include "Scripts/FSM.as"
#include "Scripts/Ragdoll.as"
#include "Scripts/Camera.as"
#include "Scripts/Menu.as"
#include "Scripts/HeadIndicator.as"
#include "Scripts/Follow.as"
#include "Scripts/PhysicsMover.as"
#include "Scripts/Debug.as"
// ------------------------------------------------
#include "Scripts/GameObject.as"
#include "Scripts/Character.as"
#include "Scripts/Enemy.as"
#include "Scripts/Thug.as"
#include "Scripts/Player.as"
#include "Scripts/Bruce.as"
#include "Scripts/DeathStroke.as"
#include "Scripts/PlayerCombat.as"
#include "Scripts/PlayerMovement.as"

void Start()
{
    LogPrint("Game Running Platform: " + GetPlatform());
    mobile = (GetPlatform() == "Android" || GetPlatform() == "iOS");
    if (mobile)
    {
        debug_draw_flag = 0;
    }
    nosound = !mobile;

    if (mobile)
        debug_mode = 0;

    g_dir_cache.Resize(4);

    if (!mobile)
    {
        render_features = RF_FULL;
        PROCESS_TIME_PER_FRAME = 6000;
    }

    Array<String>@ arguments = GetArguments();
    for (uint i = 0; i < arguments.length; ++i)
    {
        String argument = arguments[i].ToLower();
        if (argument[0] == '-')
        {
            argument = argument.Substring(1);
            if (argument == "bgm")
                nobgm = !nobgm;
            else if (argument == "bighead")
                big_head_mode = !big_head_mode;
            else if (argument == "lowend")
                render_features = RF_NONE;
            else if (debug_mode == "debug_mode")
                debug_mode = 1;
        }
    }

    cache.autoReloadResources = !mobile;
    engine.pauseMinimized = true;
    script.defaultScriptFile = scriptFile;

    SetRandomSeed(time.systemTime);

    if (!mobile)
        gDebugMgr.Start();

    SetWindowTitleAndIcon();
    CreateDebugHud();
    CreateUI();
    InitAudio();

    SubscribeToEvents();

    gGame.Start();
    gGame.ChangeState("LoadingState");

    if (nosound)
    {
        audio.masterGain[SOUND_EFFECT] = 0.0f;
    }

    if (debug_mode == 5)
    {
        ragdoll_method = 1;
    }

    LogPrint("Start Finished !!! ");
}

void Stop()
{
    LogPrint("================================= Test Stop =================================");

    globalVars["Reload"] = 1;
    if (gCameraMgr.currentController !is null && gCameraMgr.currentController.IsDebugCamera())
    {
        globalVars["CameraPos"] = gCameraMgr.cameraNode.worldPosition;
        globalVars["CameraRot"] = gCameraMgr.cameraNode.worldRotation;
    }

    globalVars["DebugDrawFlag"] = debug_draw_flag;
    globalVars["TestMode"] = debug_mode;

    if (gCameraMgr.GetCamera() !is null)
        globalVars["CameraFillMode"] = int(gCameraMgr.GetCamera().fillMode);

    Player@ p = GetPlayer();
    if (p !is null)
    {
        globalVars["PlayerPos"] = p.GetNode().worldPosition;
        globalVars["PlayerRot"] = p.GetNode().worldRotation;
    }

    if (script.defaultScene !is null)
    {
        globalVars["SceneUpdate"] = script.defaultScene.updateEnabled;
    }

    gMotionMgr.Stop();
    gDebugMgr.Stop();
    ui.Clear();
}

void InitAudio()
{
    audio.masterGain[SOUND_MASTER] = 0.5f;
    audio.masterGain[SOUND_MUSIC] = 0.5f;
    audio.masterGain[SOUND_EFFECT] = 1.0f;

    if (!nobgm)
    {
        Sound@ musicFile = cache.GetResource("Sound", "Sfx/bgm.ogg");
        musicFile.looped = true;

        BGM_BASE_FREQ = musicFile.frequency;

        // Note: the non-positional sound source component need to be attached to a node to become effective
        // Due to networked mode clearing the scene on connect, do not attach to the scene itself
        music_node = Node();
        SoundSource@ musicSource = music_node.CreateComponent("SoundSource");
        musicSource.soundType = SOUND_MUSIC;
        musicSource.gain = 0.5f;
        musicSource.Play(musicFile);
    }
}

void SetWindowTitleAndIcon()
{
    Image@ icon = cache.GetResource("Image", "Textures/UrhoIcon.png");
    graphics.windowIcon = icon;
}

void CreateDebugHud()
{
    // Create debug HUD
    DebugHud@ debugHud = engine.CreateDebugHud();
    debugHud.defaultStyle = cache.GetResource("XMLFile", "UI/DefaultStyle.xml");
}

void CreateUI()
{
    ui.root.defaultStyle = cache.GetResource("XMLFile", "UI/DefaultStyle.xml");
    // Create a Cursor UI element because we want to be able to hide and show it at will. When hidden, the mouse cursor will
    // control the camera, and when visible, it will point the raycast target
    XMLFile@ style = cache.GetResource("XMLFile", "UI/DefaultStyle.xml");
    Cursor@ cursor = Cursor();
    cursor.SetStyleAuto(style);
    ui.cursor = cursor;
    cursor.visible = true;

    gInput.CreateGUI();
}

void CreateEnemy(Scene@ _scene)
{
    Scene@ scene_ = script.defaultScene;
    if (scene_ is null)
        return;

    EnemyManager@ em = GetEnemyMgr();
    if (em is null)
        return;

    IntVector2 pos = ui.cursorPosition;
    // Check the cursor is visible and there is no UI element in front of the cursor
    if (ui.GetElementAt(pos, true) !is null)
            return;

    Camera@ camera = GetCamera();
    if (camera is null)
        return;

    Ray cameraRay = camera.GetScreenRay(float(pos.x) / graphics.width, float(pos.y) / graphics.height);
    float rayDistance = 100.0f;
    PhysicsRaycastResult result = scene_.physicsWorld.RaycastSingle(cameraRay, rayDistance, COLLISION_LAYER_LANDSCAPE);
    if (result.body is null)
        return;

    if (result.body.node.name != "floor")
        return;

    em.CreateEnemy(result.position, Quaternion(0, Random(360), 0), "Thug");
}

Player@ GetPlayer()
{
    Scene@ scene_ = script.defaultScene;
    if (scene_ is null)
        return null;
    Node@ characterNode = scene_.GetNode(player_id);
    if (characterNode is null)
        return null;
    return cast<Player>(characterNode.scriptObject);
}

Camera@ GetCamera()
{
    Scene@ scene_ = script.defaultScene;
    if (scene_ is null)
        return null;
    Node@ cameraNode = scene_.GetNode(camera_id);
    if (cameraNode is null)
        return null;
    return cameraNode.GetComponent("Camera");
}

EnemyManager@ GetEnemyMgr()
{
    Scene@ scene_ = script.defaultScene;
    if (scene_ is null)
        return null;
    return cast<EnemyManager>(scene_.GetScriptObject("EnemyManager"));
}

DebugRenderer@ GetDebugRenderer()
{
    return script.defaultScene.debugRenderer;
}

void SubscribeToEvents()
{
    SubscribeToEvent("Update", "HandleUpdate");
    SubscribeToEvent("PostRenderUpdate", "HandlePostRenderUpdate");
    SubscribeToEvent("KeyDown", "HandleKeyDown");
    SubscribeToEvent("MouseButtonDown", "HandleMouseButtonDown");
    SubscribeToEvent("MouseButtonUp", "HandleMouseButtonUp");
    SubscribeToEvent("AsyncLoadFinished", "HandleSceneLoadFinished");
    SubscribeToEvent("AsyncLoadProgress", "HandleAsyncLoadProgress");
    SubscribeToEvent("CameraEvent", "HandleCameraEvent");
    SubscribeToEvent("SliderChanged", "HandleSliderChanged");
    SubscribeToEvent("Pressed", "HandleButtonPressed");
}

void HandleUpdate(StringHash eventType, VariantMap& eventData)
{
    float timeStep = eventData["TimeStep"].GetFloat();
    gInput.Update(timeStep);
    gCameraMgr.Update(timeStep);
    gGame.Update(timeStep);
}

void HandlePostRenderUpdate(StringHash eventType, VariantMap& eventData)
{
    DrawDebug(eventData["TimeStep"].GetFloat());
}

void HandleSceneLoadFinished(StringHash eventType, VariantMap& eventData)
{
    LogPrint("HandleSceneLoadFinished");
    gGame.OnSceneLoadFinished(eventData["Scene"].GetPtr());
}

void HandleAsyncLoadProgress(StringHash eventType, VariantMap& eventData)
{
    LogPrint("HandleAsyncLoadProgress");
    Scene@ _scene = eventData["Scene"].GetPtr();
    float progress = eventData["Progress"].GetFloat();
    int loadedNodes = eventData["LoadedNodes"].GetInt();
    int totalNodes = eventData["TotalNodes"].GetInt();
    int loadedResources = eventData["LoadedResources"].GetInt();
    int totalResources = eventData["TotalResources"].GetInt();
    gGame.OnAsyncLoadProgress(_scene, progress, loadedNodes, totalNodes, loadedResources, totalResources);
}

void HandleCameraEvent(StringHash eventType, VariantMap& eventData)
{
    gCameraMgr.OnCameraEvent(eventData);
}

void PostSceneLoad()
{
    LogPrint("PostSceneLoad");

    if (globalVars.Contains("Reload"))
    {
        if (globalVars.Contains("CameraPos"))
        {
            gCameraMgr.cameraNode.worldPosition = globalVars["CameraPos"].GetVector3();
            gCameraMgr.cameraNode.worldRotation = globalVars["CameraRot"].GetQuaternion();
            gCameraMgr.SetCameraController("Debug");
        }

        if (globalVars.Contains("PlayerPos"))
        {
            Player@ p = GetPlayer();
            if (p !is null)
            {
                p.GetNode().worldPosition = globalVars["PlayerPos"].GetVector3();
                p.GetNode().worldRotation = globalVars["PlayerRot"].GetQuaternion();
            }
        }

        if (globalVars.Contains("DebugDrawFlag"))
        {
            debug_draw_flag = globalVars["DebugDrawFlag"].GetInt();
        }

        if (globalVars.Contains("TestMode"))
        {
            debug_mode = globalVars["DebugDrawFlag"].GetInt();
        }

        if (globalVars.Contains("CameraFillMode"))
        {
            gCameraMgr.GetCamera().fillMode = FillMode(globalVars["CameraFillMode"].GetInt());
        }

        if (globalVars.Contains("SceneUpdate"))
        {
            DebugPause(!globalVars["SceneUpdate"].GetBool());
        }

        globalVars.Clear();
    }
    else
    {
        if (debug_mode == 5)
        {
            debug_draw_flag = 3;
            gCameraMgr.GetCamera().fillMode = FILL_WIREFRAME;
            gCameraMgr.SetCameraController("Debug");
        }
    }

    OnDebugModeChanged();
}


/************************************************

    Util Functions

************************************************/
void LogPrint(const String&in msg)
{
    log.Info(msg);
}

void LogHint(const String&in msg, float t = 2.0f)
{
    LogPrint(msg);
    gDebugMgr.AddHintText(msg, t);
}

uint Global_AddFlag(uint flags, uint flag)
{
    flags |= flag;
    return flags;
}
uint Global_RemoveFlag(uint flags, uint flag)
{
    flags &= ~flag;
    return flags;
}
bool Global_HasFlag(uint flags, uint flag)
{
    return flags & flag != 0;
}

void CameraShake()
{
    float amount = Random(SHAKE_MIN_AMOUNT, SHAKE_MAX_AMOUNT);
    float duration = Random(SHAKE_DURATION);
    VariantMap data;
    data[NAME] = StringHash("Shake");
    data[VALUE] = amount;
    data[DURATION] = duration;
    SendEvent("CameraEvent", data);
}

PhysicsRaycastResult PhysicsRayCast(const Vector3&in start, const Vector3&in dir, float range, uint mask, bool debug = true)
{
    Scene@ scene_ = script.defaultScene;
    PhysicsWorld@ world = scene_.GetComponent("PhysicsWorld");
    PhysicsRaycastResult result = world.RaycastSingle(Ray(start, dir), range, mask);

    if (debug)
    {
        if (result.body !is null)
        {
            if (debug_draw_flag > 0)
            {
                gDebugMgr.AddCross(result.position, 0.25f, YELLOW);
                gDebugMgr.AddLine(start, result.position, Color(0.1f, 0.25f, 0.7f));
            }
        }
        else
        {
            if (debug_draw_flag > 0)
            {
                gDebugMgr.AddLine(start, dir * range + start, RED);
            }
        }
    }

    return result;
}

PhysicsRaycastResult PhysicsSphereCast(const Vector3&in start, const Vector3&in dir, float radius, float range, uint mask, bool debug = true)
{
    Scene@ scene_ = script.defaultScene;
    PhysicsWorld@ world = scene_.GetComponent("PhysicsWorld");
    PhysicsRaycastResult result = world.SphereCast(Ray(start, dir), radius, range, mask);

    if (debug)
    {
        if (result.body !is null)
        {
            if (debug_draw_flag > 0)
            {
                gDebugMgr.AddSphere(result.position, radius, YELLOW);
                gDebugMgr.AddLine(start, result.position, BLUE);
                gDebugMgr.AddLine(start, dir * range + start, WHITE);
            }
        }
        else
        {
            if (debug_draw_flag > 0)
            {
                gDebugMgr.AddLine(start, dir * range + start, RED);
            }
        }
    }

    return result;
}

PhysicsRaycastResult PhysicsSphereCast(const Vector3&in start, const Vector3&in end, float radius, uint mask, bool debug = true)
{
    Vector3 dir = end - start;
    float range = dir.length;
    dir.Normalize();
    return PhysicsSphereCast(start, dir, radius, range, mask, debug);
}

void ShowHideUIWithTag(const String&in tag, bool visible)
{
    Array<UIElement@>@ elements = ui.root.GetChildrenWithTag(tag);
    for (uint i = 0; i < elements.length; ++i)
        elements[i].visible = visible;
}

bool DebugPauseAI()
{
    return (debug_mode == 2 || debug_mode == 4 || debug_mode == 6 || debug_mode == 7);
}

/************************************************
************************************************/

class BM_Game_MotionManager : MotionManager
{
    Array<Motion@> thug_counter_arm_front_motions;
    Array<Motion@> thug_counter_arm_back_motions;
    Array<Motion@> thug_counter_leg_front_motions;
    Array<Motion@> thug_counter_leg_back_motions;
    Array<Motion@> thug_counter_double_motions;
    Array<Motion@> thug_counter_triple_motions;
    Array<Motion@> thug_counter_environment_motions;
    Array<Motion@> thug_attack_motions;

    Array<Motion@> bruce_counter_arm_front_motions;
    Array<Motion@> bruce_counter_arm_back_motions;
    Array<Motion@> bruce_counter_leg_front_motions;
    Array<Motion@> bruce_counter_leg_back_motions;
    Array<Motion@> bruce_counter_double_motions;
    Array<Motion@> bruce_counter_triple_motions;
    Array<Motion@> bruce_counter_environment_motions;

    Array<Motion@> bruce_forward_attack_motions;
    Array<Motion@> bruce_right_attack_motions;
    Array<Motion@> bruce_back_attack_motions;
    Array<Motion@> bruce_left_attack_motions;

    void AddMotions()
    {
        CreateBruceMotions();
        CreateThugMotions();
        CreateDeathStrokeMotions();
    }

    void AddTriggers()
    {
        AddBruceAnimationTriggers();
        AddThugAnimationTriggers();
        AddDeathStrokeAnimationTriggers();
    }

    void Stop()
    {
        bruce_counter_arm_front_motions.Clear();
        bruce_counter_arm_back_motions.Clear();
        bruce_counter_leg_front_motions.Clear();
        bruce_counter_leg_back_motions.Clear();
        bruce_counter_double_motions.Clear();
        bruce_counter_triple_motions.Clear();
        bruce_counter_environment_motions.Clear();

        bruce_forward_attack_motions.Clear();
        bruce_right_attack_motions.Clear();
        bruce_back_attack_motions.Clear();
        bruce_left_attack_motions.Clear();

        thug_attack_motions.Clear();
        thug_counter_arm_front_motions.Clear();
        thug_counter_arm_back_motions.Clear();
        thug_counter_leg_front_motions.Clear();
        thug_counter_leg_back_motions.Clear();
        thug_counter_double_motions.Clear();
        thug_counter_triple_motions.Clear();
        thug_counter_environment_motions.Clear();

        MotionManager::Stop();
    }
};
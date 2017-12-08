/*           ==============       ==============
            |               |____|               |
            \               /    \               /
              =============        ==============
                             ●   ●                        */

// ------------------------------------------------
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
#include "Scripts/PhysicsSensor.as"
#include "Scripts/Debug.as"
// ------------------------------------------------
#include "Scripts/GameObject.as"
#include "Scripts/Character.as"
#include "Scripts/Enemy.as"
#include "Scripts/Thug.as"
#include "Scripts/Player.as"
#include "Scripts/Bruce.as"
#include "Scripts/PlayerCombat.as"
#include "Scripts/PlayerMovement.as"

enum RenderFeature
{
    RF_NONE     = 0,
    RF_SHADOWS  = (1 << 0),
    RF_HDR      = (1 << 1),
    RF_AA       = (1 << 2),
    RF_FULL     = RF_SHADOWS | RF_HDR | RF_AA,
};

int drawDebug = 2;
bool bigHeadMode = false;
bool nobgm = true;

Node@ musicNode;
float BGM_BASE_FREQ = 44100;

String CAMERA_NAME = "Camera";

uint cameraId = M_MAX_UNSIGNED;
uint playerId = M_MAX_UNSIGNED;

int test_enemy_num_override = 10;
int render_features = RF_SHADOWS | RF_HDR;

const String UI_FONT = "Fonts/unlearn2.ttf";
int UI_FONT_SIZE = 40;
const String DEBUG_FONT = "Fonts/seagle.otf";
int DEBUG_FONT_SIZE = 20;

const String GAME_CAMEAR_NAME = "ThirdPerson";

int freeze_ai = 0;
Array<int> dirCache;
Array<int> zoneDirCache;
Array<int> gIntCache;
Array<int> gIntCache2;
Array<float> gFloatCache;

bool mobile = false;
bool one_shot_kill = false;
bool instant_collision = true;
bool player_walk = false;
bool locomotion_turn = true;
bool attack_choose_closest_one = false;
bool counter_choose_closest_one = false;

const Color TARGET_COLOR(0.25f, 0.28f, 0.7f);
const Color SOURCE_COLOR(0.75f, 0.28f, 0.27f);

GameInput@ gInput = GameInput();

void Start()
{
    LogPrint("Game Running Platform: " + GetPlatform());
    mobile = (GetPlatform() == "Android" || GetPlatform() == "iOS");
    if (mobile)
        drawDebug = 0;

    dirCache.Resize(4);
    zoneDirCache.Resize(NUM_ZONE_DIRECTIONS);

    if (!mobile)
        render_features = RF_FULL;

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
                bigHeadMode = !bigHeadMode;
            else if (argument == "lowend")
                render_features = RF_NONE;
            else if (argument == "freezeai")
                freeze_ai = 1;
        }
    }

    cache.autoReloadResources = !mobile;
    engine.pauseMinimized = true;
    script.defaultScriptFile = scriptFile;

    SetRandomSeed(time.systemTime);
    @gMotionMgr = BM_Game_MotionManager();

    SetWindowTitleAndIcon();
    CreateDebugHud();
    CreateUI();
    InitAudio();

    SubscribeToEvents();

    gGame.Start();
    gGame.ChangeState("LoadingState");

    LogPrint("Start Finished !!! ");
}

void Stop()
{
    LogPrint("================================= Test Stop =================================");
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
        musicNode = Node();
        SoundSource@ musicSource = musicNode.CreateComponent("SoundSource");
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
    cursor.visible = false;

    // Set starting position of the cursor at the rendering window center
    //cursor.SetPosition(graphics.width / 2, graphics.height / 2);
    Text@ text = ui.root.CreateChild("Text", "debug");
    text.SetFont(cache.GetResource("Font", DEBUG_FONT), DEBUG_FONT_SIZE);
    text.SetPosition(5, 50);
    text.color = YELLOW;
    text.priority = -99999;
    text.visible = false;
    // text.textEffect = TE_SHADOW;

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
    Node@ characterNode = scene_.GetNode(playerId);
    if (characterNode is null)
        return null;
    return cast<Player>(characterNode.scriptObject);
}

Camera@ GetCamera()
{
    Scene@ scene_ = script.defaultScene;
    if (scene_ is null)
        return null;
    Node@ cameraNode = scene_.GetNode(cameraId);
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
}

void HandleUpdate(StringHash eventType, VariantMap& eventData)
{
    float timeStep = eventData["TimeStep"].GetFloat();
    gInput.Update(timeStep);
    gCameraMgr.Update(timeStep);
    gGame.Update(timeStep);
    if (drawDebug > 0)
    {
        DrawDebugText();
    }
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


/************************************************

    Util Functions

************************************************/
void LogPrint(const String&in msg)
{
    log.Info(msg);
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
    float amount = Random(5.0f, 20.0f);
    float duration = Random(1.0f);
    VariantMap data;
    data[NAME] = StringHash("Shake");
    data[VALUE] = amount;
    data[DURATION] = duration;
    SendEvent("CameraEvent", data);
}

PhysicsRaycastResult PhysicsRaycast(const Vector3&in start, const Vector3&in dir, float range, uint mask)
{
    Scene@ scene_ = script.defaultScene;
    PhysicsWorld@ world = scene_.GetComponent("PhysicsWorld");
    PhysicsRaycastResult result = world.RaycastSingle(Ray(start, dir), range, mask);
    if (result.body !is null)
    {
        if (drawDebug > 0)
        {
            gDebugMgr.AddCross(result.position, 0.25f, YELLOW);
            gDebugMgr.AddLine(start, result.position, RED);
        }
    }
    else
    {
        if (drawDebug > 0)
        {
            gDebugMgr.AddLine(start, dir * range + start, RED);
        }
    }
    return result;
}
/************************************************
************************************************/

class BM_Game_MotionManager : MotionManager
{
    void AddMotions()
    {
        CreateBruceMotions();
        CreateThugMotions();
    }

    void AddTriggers()
    {
        AddBruceAnimationTriggers();
        AddThugAnimationTriggers();
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
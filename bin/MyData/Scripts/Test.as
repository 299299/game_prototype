

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

int drawDebug = 3;
bool bigHeadMode = false;
bool nobgm = true;

Node@ musicNode;
float BGM_BASE_FREQ = 44100;

String CAMERA_NAME = "Camera";

uint cameraId = M_MAX_UNSIGNED;
uint playerId = M_MAX_UNSIGNED;

int test_enemy_num_override = 20;
int render_features = RF_SHADOWS | RF_HDR;

const String UI_FONT = "Fonts/unlearn2.ttf";
int UI_FONT_SIZE = 40;
const String DEBUG_FONT = "Fonts/seagle.otf";
int DEBUG_FONT_SIZE = 12;

int freeze_ai = 0;
int test_beat_index = 1;
bool base_on_player = false;
int test_counter_index = 0;
int test_double_counter_index = 0;
int test_triple_counter_index = 0;
int collision_type = 0;
Array<int> dirCache;
Array<int> zoneDirCache;

bool mobile = false;

GameInput@ gInput = GameInput();

void Start()
{
    LogPrint("Game Running Platform: " + GetPlatform());
    mobile = (GetPlatform() == "Android" || GetPlatform() == "iOS");

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
            else if (argument == "reflection")
                reflection = !reflection;
        }
    }

    cache.autoReloadResources = !mobile;
    engine.pauseMinimized = true;
    script.defaultScriptFile = scriptFile;

    SetRandomSeed(time.systemTime);
    @gMotionMgr = BM_Game_MotionManager();

    SetWindowTitleAndIcon();
    CreateConsoleAndDebugHud();
    CreateUI();
    InitAudio();

    SubscribeToEvents();

    gGame.Start();
    gGame.ChangeState("LoadingState");

    CreateConsoleAndDebugHud();

    LogPrint("Start Finished !!! ");
}

void Stop()
{
    LogPrint("Test Stop");
    gMotionMgr.Stop();
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

void CreateConsoleAndDebugHud()
{
    // Get default style
    XMLFile@ xmlFile = cache.GetResource("XMLFile", "UI/DefaultStyle.xml");
    if (xmlFile is null)
        return;

    // Create consoleui
    Console@ console = engine.CreateConsole();
    console.defaultStyle = xmlFile;
    console.background.opacity = 0.8f;

    // Create debug HUD
    DebugHud@ debugHud = engine.CreateDebugHud();
    debugHud.defaultStyle = xmlFile;
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
    text.horizontalAlignment = HA_LEFT;
    text.verticalAlignment = VA_TOP;
    text.SetPosition(5, 50);
    text.color = Color(0, 0, 1);
    text.priority = -99999;
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
    SubscribeToEvent("CrowdAgentFailure", "HandleCrowdAgentFailure");
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
    DrawDebug();
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


void HandleCrowdAgentFailure(StringHash eventType, VariantMap& eventData)
{
    Node@ node = eventData["Node"].GetPtr();
    int state = eventData["CrowdAgentState"].GetInt();

    LogPrint(node.name + " state = " + state);

    // If the agent's state is invalid, likely from spawning on the side of a box, find a point in a larger area
    if (state == CA_STATE_INVALID)
    {
        Scene@ scene_ = script.defaultScene;
        // Get a point on the navmesh using more generous extents
        Vector3 newPos = cast<DynamicNavigationMesh>(scene_.GetComponent("DynamicNavigationMesh")).FindNearestPoint(node.position, Vector3(5.0f,5.0f,5.0f));
        // Set the new node position, CrowdAgent component will automatically reset the state of the agent
        node.worldPosition = newPos;
    }
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
};
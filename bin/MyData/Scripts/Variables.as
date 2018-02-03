// ==============================================
//
//    DEBUG GLOBAL
//
// ==============================================
const Color TARGET_COLOR(0.25f, 0.28f, 0.7f);
const Color SOURCE_COLOR(0.75f, 0.28f, 0.27f);

int test_beat_index = 1;
bool base_on_player = false;
int test_counter_index = 0;
int test_double_counter_index = 0;
int test_triple_counter_index = 0;
int test_attack_id = 0;
int test_environment_counter_index = 0;
int debug_draw_flag = 2;

const float sliderRange = 20.0f;
const float cameraDistMin = 3.0f;
const float cameraDistMax = 40.0f;
const float cameraPitchMin = -60.0f;
const float cameraPitchMax = 90.0f;
const String TAG_DEBUG = "TAG_DEBUG";
const String TAG_DEBUG_ANIM = "TAG_DEBUG_ANIM";

// ==============================================
//
//    GANME OBJECT GLOBAL
//
// ==============================================
const int CTRL_ATTACK = (1 << 0);
const int CTRL_JUMP = (1 << 1);
const int CTRL_ALL = (1 << 16);

const uint FLAGS_ATTACK  = (1 << 0);
const uint FLAGS_COUNTER = (1 << 1);
const uint FLAGS_NO_MOVE = (1 << 2);
const uint FLAGS_MOVING = (1 << 3);
const uint FLAGS_INVINCIBLE = (1 << 4);
const uint FLAGS_STUN = (1 << 5);
const uint FLAGS_KEEP_DIST = (1 << 6);
const uint FLAGS_RUN_TO_ATTACK = (1 << 7);
const uint FLAGS_DEAD = (1 << 8);
const uint FLAGS_COLLISION_AVOIDENCE = (1 << 9);
const uint FLAGS_HIT_RAGDOLL = (1 << 10);
const uint FLAGS_TAUNT = (1 << 11);

const uint COLLISION_LAYER_LANDSCAPE = (1 << 0);
const uint COLLISION_LAYER_CHARACTER = (1 << 1);
const uint COLLISION_LAYER_PROP      = (1 << 2);
const uint COLLISION_LAYER_RAGDOLL   = (1 << 3);
// const uint COLLISION_LAYER_WALL      = (1 << 4);

// ==============================================
//
//    CHARACTER GLOBAL
//
// ==============================================
const float FULLTURN_THRESHOLD = 125;
const float COLLISION_RADIUS = 1.45f;
const float COLLISION_SAFE_DIST = COLLISION_RADIUS * 2.0f + 0.1f;
const float CHARACTER_HEIGHT = 5.0f;
const float SPHERE_CAST_RADIUS = 0.25f;

const int MAX_NUM_OF_ATTACK = 3;
const int MAX_NUM_OF_MOVING = 3;
const int MAX_NUM_OF_NEAR = 4;
const int MAX_NUM_OF_RUN_ATTACK = 3;

const int INITIAL_HEALTH = 100;
const float IN_AIR_FOOT_HEIGHT = 0.75f;
const float KEEP_TARGET_DISTANCE = COLLISION_SAFE_DIST - 0.5f;
const Vector3 COLLISION_OFFSET(0, CHARACTER_HEIGHT/2.0f, 0.3f);

const StringHash ATTACK_STATE("AttackState");
const StringHash HIT_STATE("HitState");
const StringHash STAND_STATE("StandState");

const StringHash ANIMATION_INDEX("AnimationIndex");
const StringHash ATTACK_TYPE("AttackType");
const StringHash TIME_SCALE("TimeScale");
const StringHash DATA("Data");
const StringHash NAME("Name");
const StringHash ANIMATION("Animation");
const StringHash STATE("State");
const StringHash VALUE("Value");
const StringHash COUNTER_CHECK("CounterCheck");
const StringHash ATTACK_CHECK("AttackCheck");
const StringHash BONE("Bone");
const StringHash NODE("Node");
const StringHash COMBAT_SOUND("CombatSound");
const StringHash COMBAT_SOUND_LARGE("CombatSoundLarge");
const StringHash PARTICLE("Particle");
const StringHash DURATION("Duration");
const StringHash READY_TO_FIGHT("ReadyToFight");
const StringHash FOOT_STEP("FootStep");
const StringHash CHANGE_STATE("ChangeState");
const StringHash IMPACT("Impact");
const StringHash SOUND("Sound");
const StringHash TARGET("Target");
const StringHash DIRECTION("Direction");

const String PLAYER_TAG("Tag_Player");
const String ENEMY_TAG("Tag_Enemy");

const int num_of_sounds = 37;
const int num_of_big_sounds = 6;

Vector3 WORLD_HALF_SIZE(1000, 0, 1000);


// ==============================================
//
//    PLAYER GLOBAL
//
// ==============================================
const float MAX_COUNTER_DIST = 4.5f;
const float DIST_SCORE = 40.0f;
const float ANGLE_SCORE = 30.0f;
const float THREAT_SCORE = 30.0f;
const int   MAX_WEAK_ATTACK_COMBO = 3;
const float MAX_DISTRACT_DIST = 4.0f;
const float MAX_DISTRACT_DIR = 90.0f;
const int   HIT_WAIT_FRAMES = 3;
const float LAST_KILL_SPEED = 0.35f;
const float COUNTER_ALIGN_MAX_DIST = 1.0f;
const float GOOD_COUNTER_DIST = 4.0f;
const float ATTACK_DIST_PICK_LONG_RANGE = 5.0f;
const float ATTACK_DIST_PICK_SHORT_RANGE = 5.0f;
const float MAX_ATTACK_CHECK_DIST = 3.0f;
float MAX_ATTACK_DIST = 20.0f;

// ==============================================
//
//    THUG GLOBAL
//
// ==============================================
const String MOVEMENT_GROUP_THUG = "TG_Combat/";
const float MIN_TURN_ANGLE = 20;
const float MIN_THINK_TIME = 0.25f;
const float MAX_THINK_TIME = 1.0f;
const float MAX_ATTACK_RANGE = 3.8f;
const float HIT_RAGDOLL_FORCE = 25.0f;

const float AI_FAR_DIST = 15.0f;
const float AI_NEAR_DIST = 7.5f;
const float AI_MAX_STATE_TIME = 10.0f;
const float RAGDOLL_HIT_VEL = 15.0f;

// ==============================================
//
//    DEATHSTROKE GLOBAL
//
// ==============================================
const String DK_MOVEMENT_GROUP = "DK_Movement/";

// ==============================================
//
//    BRUCE GLOBAL
//
// ==============================================
const String BRUCE_MOVEMENT_GROUP = "BM_Combat_Movement/";

// ==============================================
//
//    CAMERA GLOBAL
//
// ==============================================
const StringHash TARGET_POSITION("TargetPosition");
const StringHash TARGET_ROTATION("TargetRotation");
const StringHash TARGET_CONTROLLER("TargetController");
const StringHash TARGET_FOV("TargetFOV");
const float BASE_FOV = 45.0f;
const float SHAKE_DURATION = 1.0f;
const float SHAKE_MIN_AMOUNT = 0.1f;
const float SHAKE_MAX_AMOUNT = 0.25f;

// ==============================================
//
//    INPUT GLOBAL
//
// ==============================================
enum InputAction
{
    kInputAttack = 0,
    kInputCounter,
    kInputDistract,
    kInputEvade,
};

bool  freeze_input = false;
const float TOUCH_SCALE_X = 0.15f;
const float BUTTON_SCALE_X = 0.1f;
const float BORDER_OFFSET = 10.0f;
const String TAG_INPUT = "tag_input";
const String TOUCH_BTN_NAME = "touch_move";
const String TOUCH_ICON_NAME = "touch_move_icon";


// ==============================================
//
//    GAME GLOBAL
//
// ==============================================
enum RenderFeature
{
    RF_NONE     = 0,
    RF_SHADOWS  = (1 << 0),
    RF_HDR      = (1 << 1),
    RF_AA       = (1 << 2),
    RF_FULL     = RF_SHADOWS | RF_HDR | RF_AA,
};

const String CAMERA_NAME = "Camera";
const String UI_FONT = "Fonts/angrybirds-regular.ttf";
const int UI_FONT_SIZE = 40;
const String DEBUG_FONT = "Fonts/Anonymous Pro.ttf";
const int DEBUG_FONT_SIZE = 20;
const String GAME_CAMEAR_NAME = "ThirdPerson";

const int LAYER_MOVE = 0;
const int LAYER_ATTACK = 1;

enum AttackType
{
    ATTACK_PUNCH,
    ATTACK_KICK,
};

const String TAG_LOADING = "TAG_LOADING";

bool big_head_mode = false;
bool nobgm = true;
bool nosound = true;

Node@ music_node;
float BGM_BASE_FREQ = 44100;

uint camera_id = M_MAX_UNSIGNED;
uint player_id = M_MAX_UNSIGNED;

int test_enemy_num_override = 20;
int render_features = RF_SHADOWS | RF_HDR;

Array<int> g_dir_cache;
Array<int> g_int_cache;
Array<Vector3> g_v3_cache;

bool mobile = false;
bool one_shot_kill = false;
bool instant_collision = true;
bool player_walk = true;
bool locomotion_turn = true;
bool attack_choose_closest_one = false;
bool counter_choose_closest_one = false;

int game_state = 0;
int collision_type = 0;
int PROCESS_TIME_PER_FRAME = 60; // ms
bool camera_collison = false;
bool camera_shake = true;
// test mode
// 1 --> test attack location pick
// 2 --> test thug hit reaction
// 3 --> test player 1.5 time scale
// 4 --> test ragdoll hit
// 5 --> test ragdoll creation
// 6 --> test ai move behavior
// 7 --> debug ui parameter tweak
// 8 --> debug animation
int debug_mode = 2;

// ==============================================
//
//   GLOBAL INSTANCES
//
// ==============================================
GameInput@ gInput = GameInput();
MotionManager@ gMotionMgr = BM_Game_MotionManager();
GameFSM@ gGame = GameFSM();
CameraManager@ gCameraMgr = CameraManager();

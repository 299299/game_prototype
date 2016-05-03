// ==============================================
//
//    Batman Class
//
// ==============================================

class BatmanStandState : PlayerStandState
{
    BatmanStandState(Character@ c)
    {
        super(c);
        AddMotion("BM_Movement/Stand_Idle");
    }
};

class BatmanTurnState : PlayerTurnState
{
    BatmanTurnState(Character@ c)
    {
        super(c);
        AddMotion("BM_Movement/Turn_Right_90");
        AddMotion("BM_Movement/Turn_Right_180");
        AddMotion("BM_Movement/Turn_Left_90");
    }
};

class BatmanStandToWalkState : PlayerStandToWalkState
{
    BatmanStandToWalkState(Character@ c)
    {
        super(c);
        AddMotion("BM_Movement/Stand_To_Walk_Right_90");
        AddMotion("BM_Movement/Stand_To_Walk_Right_180");
        AddMotion("BM_Movement/Stand_To_Walk_Right_180");
    }
};

class BatmanWalkState : PlayerWalkState
{
    BatmanWalkState(Character@ c)
    {
        super(c);
        SetMotion("BM_Movement/Walk");
    }

    void Enter(State@ lastState)
    {
        startTime = (lastState.name == "StandToWalkState") ? 14 * SEC_PER_FRAME : 0;
        PlayerMoveForwardState::Enter(lastState);
    }
};

class BatmanStandToRunState : PlayerStandToRunState
{
    BatmanStandToRunState(Character@ c)
    {
        super(c);
        // AddMotion("BM_Movement/Stand_To_Run");
        AddMotion("BM_Movement/Stand_To_Run_Right_90");
        AddMotion("BM_Movement/Stand_To_Run_Right_180");
        AddMotion("BM_Movement/Stand_To_Run_Right_180");
    }
};

class BatmanRunState : PlayerRunState
{
    BatmanRunState(Character@ c)
    {
        super(c);
        SetMotion("BM_Movement/Run");
    }

    void Enter(State@ lastState)
    {
        blendTime = 0.2f;//(lastState.name == "RunTurn180State") ? 0.01 : 0.2f;
        startTime = 0.0f;
        if (lastState.name == "StandToRunState")
            startTime = 9 * SEC_PER_FRAME;
        else if (lastState.name == "RunTurn180State")
            startTime = 10 * SEC_PER_FRAME;
        PlayerMoveForwardState::Enter(lastState);
    }
};

class BatmanRunToStandState : PlayerRunToStandState
{
    BatmanRunToStandState(Character@ c)
    {
        super(c);
        SetMotion("BM_Movement/Run_Right_Passing_To_Stand");
    }
};

class BatmanRunTurn180State : PlayerRunTurn180State
{
    BatmanRunTurn180State(Character@ c)
    {
        super(c);
        SetMotion("BM_Movement/Run_Right_Passing_To_Run_Right_180");
    }
};

class BatmanEvadeState : PlayerEvadeState
{
    BatmanEvadeState(Character@ c)
    {
        super(c);
        SetMotion("BM_Combat/Evade_Forward_03");
    }
};

class BatmanAttackState : PlayerAttackState
{
    BatmanAttackState(Character@ c)
    {
        super(c);

         //========================================================================
        // FORWARD
        //========================================================================
        AddAttackMotion(forwardAttacks, "Attack_Close_Weak_Forward", 11, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Close_Weak_Forward_01", 12, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Close_Weak_Forward_02", 12, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Close_Weak_Forward_03", 11, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Close_Weak_Forward_04", 16, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_02", 14, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_03", 11, ATTACK_KICK, L_FOOT);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_06", 20, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_08", 18, ATTACK_PUNCH, R_ARM);
        AddAttackMotion(forwardAttacks, "Attack_Close_Run_Forward", 12, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Far_Forward", 25, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Far_Forward_03", 22, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Run_Far_Forward", 18, ATTACK_KICK, R_FOOT);

        //========================================================================
        // RIGHT
        //========================================================================
        AddAttackMotion(rightAttacks, "Attack_Close_Weak_Right", 12, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(rightAttacks, "Attack_Close_Weak_Right_01", 10, ATTACK_PUNCH, R_ARM);
        AddAttackMotion(rightAttacks, "Attack_Close_Weak_Right_02", 15, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(rightAttacks, "Attack_Close_Right", 16, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_01", 18, ATTACK_PUNCH, R_ARM);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_05", 15, ATTACK_KICK, L_CALF);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_07", 18, ATTACK_PUNCH, R_ARM);
        //AddAttackMotion(rightAttacks, "Attack_Far_Right_02", 21, ATTACK_PUNCH, R_HAND);

        //========================================================================
        // BACK
        //========================================================================
        // back weak
        AddAttackMotion(backAttacks, "Attack_Close_Weak_Back", 12, ATTACK_PUNCH, L_ARM);
        AddAttackMotion(backAttacks, "Attack_Close_Weak_Back_01", 12, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(backAttacks, "Attack_Close_Back", 11, ATTACK_PUNCH, L_ARM);
        AddAttackMotion(backAttacks, "Attack_Close_Back_01", 16, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(backAttacks, "Attack_Close_Back_03", 21, ATTACK_KICK, R_FOOT);
        AddAttackMotion(backAttacks, "Attack_Close_Back_04", 18, ATTACK_KICK, R_FOOT);
        AddAttackMotion(backAttacks, "Attack_Close_Back_05", 14, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(backAttacks, "Attack_Close_Back_06", 15, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(backAttacks, "Attack_Close_Back_08", 17, ATTACK_KICK, L_FOOT);
        AddAttackMotion(backAttacks, "Attack_Far_Back", 14, ATTACK_KICK, L_FOOT);
        AddAttackMotion(backAttacks, "Attack_Far_Back_01", 15, ATTACK_KICK, L_FOOT);

        //========================================================================
        // LEFT
        //========================================================================
        // left weak
        AddAttackMotion(leftAttacks, "Attack_Close_Weak_Left", 13, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(leftAttacks, "Attack_Close_Weak_Left_01", 12, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(leftAttacks, "Attack_Close_Weak_Left_02", 13, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(leftAttacks, "Attack_Close_Left", 7, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_02", 13, ATTACK_KICK, R_FOOT);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_05", 15, ATTACK_KICK, L_FOOT);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_06", 12, ATTACK_KICK, R_FOOT);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_07", 15, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(leftAttacks, "Attack_Far_Left_02", 22, ATTACK_PUNCH, R_ARM);
        AddAttackMotion(leftAttacks, "Attack_Far_Left_03", 21, ATTACK_KICK, L_FOOT);

        PostInit();
    }

    void AddAttackMotion(Array<AttackMotion@>@ attacks, const String&in name, int frame, int type, const String&in bName)
    {
        attacks.Push(AttackMotion("BW_Attack/" + name, frame, type, bName));
    }
};


class BatmanCounterState : PlayerCounterState
{
    BatmanCounterState(Character@ c)
    {
        super(c);
        Add_Counter_Animations("BM_TG_Counter/");
    }
};

class BatmanHitState : PlayerHitState
{
    BatmanHitState(Character@ c)
    {
        super(c);
        String hitPrefix = "BM_HitReaction/";
        AddMotion(hitPrefix + "HitReaction_Face_Right");
        AddMotion(hitPrefix + "Hit_Reaction_SideLeft");
        AddMotion(hitPrefix + "HitReaction_Back");
        AddMotion(hitPrefix + "Hit_Reaction_SideRight");
    }
};

class BatmanDeadState : PlayerDeadState
{
    BatmanDeadState(Character@ c)
    {
        super(c);
        String prefix = "BM_Death_Primers/";
        AddMotion(prefix + "Death_Front");
        AddMotion(prefix + "Death_Side_Left");
        AddMotion(prefix + "Death_Back");
        AddMotion(prefix + "Death_Side_Right");
    }
};

class BatmanCrouchState : PlayerCrouchState
{
    BatmanCrouchState(Character@ c)
    {
        super(c);
        SetMotion("BM_Movement/Crouch_Idle");
    }
};

class BatmanCrouchTurnState : PlayerCrouchTurnState
{
    BatmanCrouchTurnState(Character@ c)
    {
        super(c);
        AddMotion("BM_Crouch_Turns/Turn_Right_90");
        AddMotion("BM_Crouch_Turns/Turn_Right_180");
        AddMotion("BM_Crouch_Turns/Turn_Left_90");
    }
};

class BatmanCrouchMoveState : PlayerCrouchMoveState
{
    BatmanCrouchMoveState(Character@ c)
    {
        super(c);
        SetMotion("BM_Movement/Cover_Run");
        animSpeed = 0.5f;
    }
};

class BatmanFallState : PlayerFallState
{
    BatmanFallState(Character@ c)
    {
        super(c);
        SetMotion("BM_Movement/Fall");
    }
};

class BatmanLandState : PlayerLandState
{
    BatmanLandState(Character@ c)
    {
        super(c);
        SetMotion("BM_Movement/Land");
    }
};

class BatmanCoverState : PlayerCoverState
{
    BatmanCoverState(Character@ c)
    {
        super(c);
        SetMotion("BM_Movement/Cover_Idle");
    }
};

class BatmanCoverRunState : PlayerCoverRunState
{
    BatmanCoverRunState(Character@ c)
    {
        super(c);
        SetMotion("BM_Movement/Cover_Run");
        animSpeed = 0.5f;
    }
};

class BatmanCoverTransitionState : PlayerCoverTransitionState
{
    BatmanCoverTransitionState(Character@ c)
    {
        super(c);
        SetMotion("BM_Movement/Cover_Transition");
    }
};

class BatmanClimbOverState : PlayerClimbOverState
{
    BatmanClimbOverState(Character@ c)
    {
        super(c);
        AddMotion("BM_Climb/Stand_Climb_Over_128_Fall");
        AddMotion("BM_Climb/Stand_Climb_Over_256_Fall");

        AddMotion("BM_Climb/Run_Climb_Over_128_Fall");
        AddMotion("BM_Climb/Run_Climb_Over_256_Fall");

        AddMotion("BM_Climb/Stand_Climb_Over_128");
        AddMotion("BM_Climb/Run_Climb_Over_128");

        AddMotion("BM_Climb/Crouch_Jump_128_To_Hang");
        AddMotion("BM_Climb/Crouch_Jump_128_To_Dangle");
    }
};

class BatmanClimbUpState : PlayerClimbUpState
{
    BatmanClimbUpState(Character@ c)
    {
        super(c);
        AddMotion("BM_Climb/Stand_Climb_Up_128");
        AddMotion("BM_Climb/Stand_Climb_Up_256");
        AddMotion("BM_Climb/Stand_Climb_Up_384");
        AddMotion("BM_Climb/Run_Climb_Up_128");
        AddMotion("BM_Climb/Run_Climb_Up_256");
        AddMotion("BM_Climb/Run_Climb_Up_384");
    }
};

class BatmanHangUpState : PlayerHangUpState
{
    BatmanHangUpState(Character@ c)
    {
        super(c);
        AddMotion("BM_Climb/Stand_Climb_Up_256_Hang");
        AddMotion("BM_Climb/Stand_Climb_Up_384_Hang");
        AddMotion("BM_Climb/Run_Climb_Up_256_Hang");
        AddMotion("BM_Climb/Run_Climb_Up_384_Hang");
    }
};

class BatmanHangIdleState : PlayerHangIdleState
{
    BatmanHangIdleState(Character@ c)
    {
        super(c);

        AddMotion("BM_Climb/Hang_Left_End");
        AddMotion("BM_Climb/Hang_Right_End");
    }
};

class BatmanHangOverState : PlayerHangOverState
{
    BatmanHangOverState(Character@ c)
    {
        super(c);
        AddMotion("BM_Climb/Hang_Climb_Up_Run");
        AddMotion("BM_Climb/Hang_Climb_Up_Over_128");
        AddMotion("BM_Climb/Hang_Jump_Over_128");
        AddMotion("BM_Climb/Hang_Jump_Over_Fall");
    }
};

class BatmanHangMoveState : PlayerHangMoveState
{
    BatmanHangMoveState(Character@ c)
    {
        super(c);
        AddMotion("BM_Climb/Hang_Left");
        AddMotion("BM_Climb/Hang_Left_Convex");
        AddMotion("BM_Climb/Hang_Left_Concave");
        AddMotion("BM_Climb/Hang_Right");
        AddMotion("BM_Climb/Hang_Right_Convex");
        AddMotion("BM_Climb/Hang_Right_Concave");
    }
};

class BatmanDangleIdleState : PlayerDangleIdleState
{
    BatmanDangleIdleState(Character@ c)
    {
        super(c);

        AddMotion("BM_Climb/Dangle_Left_End");
        AddMotion("BM_Climb/Dangle_Right_End");

        //AddMotion("BM_Climb/Dangle_Idle");
        idleAnim = GetAnimationName("BM_Climb/Dangle_Idle");
    }
};

class BatmanDangleOverState : PlayerDangleOverState
{
    BatmanDangleOverState(Character@ c)
    {
        super(c);
        AddMotion("BM_Climb/Dangle_Climb_Up_Run");
        AddMotion("BM_Climb/Dangle_Climb_Up_Over_128");
        AddMotion("BM_Climb/Hang_Jump_Over_128");
        AddMotion("BM_Climb/Hang_Jump_Over_Fall");
    }
};

class BatmanDangleMoveState : PlayerDangleMoveState
{
    BatmanDangleMoveState(Character@ c)
    {
        super(c);
        AddMotion("BM_Climb/Dangle_Left");
        AddMotion("BM_Climb/Dangle_Convex_90_L");
        AddMotion("BM_Climb/Dangle_Concave_90_L");
        AddMotion("BM_Climb/Dangle_Right");
        AddMotion("BM_Climb/Dangle_Convex_90_R");
        AddMotion("BM_Climb/Dangle_Concave_90_R");
    }
};

class BatmanClimbDownState : PlayerClimbDownState
{
    BatmanClimbDownState(Character@ c)
    {
        super(c);

        AddMotion("BM_Climb/Crouch_To_Hang");
        AddMotion("BM_Climb/Crouch_To_Dangle");
    }
};

class Batman : Player
{
    Batman()
    {
        super();
        walkAlignAnimation = GetAnimationName("BM_Movement/Walk");
    }

    void AddStates()
    {
        stateMachine.AddState(BatmanStandState(this));
        stateMachine.AddState(BatmanTurnState(this));
        stateMachine.AddState(BatmanWalkState(this));
        stateMachine.AddState(BatmanRunState(this));
        stateMachine.AddState(BatmanRunToStandState(this));
        stateMachine.AddState(BatmanRunTurn180State(this));
        stateMachine.AddState(BatmanEvadeState(this));
        stateMachine.AddState(CharacterAlignState(this));
        stateMachine.AddState(AnimationTestState(this));
        stateMachine.AddState(BatmanStandToWalkState(this));
        stateMachine.AddState(BatmanStandToRunState(this));

        if (game_type == 0)
        {
            stateMachine.AddState(BatmanAttackState(this));
            stateMachine.AddState(BatmanCounterState(this));
            stateMachine.AddState(BatmanHitState(this));
            stateMachine.AddState(BatmanDeadState(this));
        }
        else if (game_type == 1)
        {
            stateMachine.AddState(BatmanCrouchState(this));
            stateMachine.AddState(BatmanCrouchTurnState(this));
            stateMachine.AddState(BatmanCrouchMoveState(this));
            stateMachine.AddState(BatmanFallState(this));
            stateMachine.AddState(BatmanLandState(this));
            stateMachine.AddState(BatmanCoverState(this));
            stateMachine.AddState(BatmanCoverRunState(this));
            stateMachine.AddState(BatmanCoverTransitionState(this));
            // climb
            stateMachine.AddState(BatmanClimbOverState(this));
            stateMachine.AddState(BatmanClimbUpState(this));
            stateMachine.AddState(BatmanClimbDownState(this));
            // hang
            stateMachine.AddState(BatmanHangUpState(this));
            stateMachine.AddState(BatmanHangIdleState(this));
            stateMachine.AddState(BatmanHangOverState(this));
            stateMachine.AddState(BatmanHangMoveState(this));
            // dangle
            stateMachine.AddState(BatmanDangleIdleState(this));
            stateMachine.AddState(BatmanDangleOverState(this));
            stateMachine.AddState(BatmanDangleMoveState(this));
        }
    }
};

void Create_BM_ClimbAnimations()
{
    Vector3 offset;
    String preFix = "BM_Climb/";
    int flags = kMotion_YZ | kMotion_Ext_Adjust_Y;

    // Climb Over
    Global_CreateMotion(preFix + "Run_Climb_Over_128", kMotion_Z, kMotion_ALL, 37).SetDockAlign(L_HAND, 0.5f, Vector3(0, -0.1, 0));
    Global_CreateMotion(preFix + "Run_Climb_Over_128_Fall", kMotion_YZ).SetDockAlign(L_HAND, 0.5f, Vector3(0, -0.1, 0));
    Global_CreateMotion(preFix + "Run_Climb_Over_256_Fall", kMotion_YZ).SetDockAlign(L_HAND, 0.5f, Vector3(0, -0.1, 0));

    Global_CreateMotion(preFix + "Stand_Climb_Over_128", kMotion_Z).SetDockAlign(L_HAND, 0.5f, Vector3(0, -0.1, 0));
    Global_CreateMotion(preFix + "Stand_Climb_Over_128_Fall", kMotion_YZ).SetDockAlign(L_HAND, 0.5f, Vector3(0, -0.1, 0));
    Global_CreateMotion(preFix + "Stand_Climb_Over_256_Fall", kMotion_YZ).SetDockAlign(L_HAND, 0.5f, Vector3(0, -0.1, 0));

    // Climb Up
    Global_CreateMotion(preFix + "Stand_Climb_Up_128", kMotion_YZ).SetDockAlign(L_FOOT, 0.27f, Vector3(0, -0.3, 0));
    Global_CreateMotion(preFix + "Run_Climb_Up_128", kMotion_YZ, kMotion_ALL, 20).SetDockAlign(L_FOOT, 0.35f, Vector3(0, -0.1, 0));

    Global_CreateMotion(preFix + "Stand_Climb_Up_256", kMotion_YZ).SetDockAlign(L_HAND, 0.8f, Vector3(0, -0.1, 0.3));
    Global_CreateMotion(preFix + "Run_Climb_Up_256", kMotion_YZ).SetDockAlign(L_HAND, 0.8f, Vector3(0, -0.1, 0.2));
    Global_CreateMotion(preFix + "Stand_Climb_Up_384", kMotion_YZ).SetDockAlign(L_HAND, 0.8f, Vector3(0, -0.1, 0.1));
    Global_CreateMotion(preFix + "Run_Climb_Up_384", kMotion_YZ).SetDockAlign(L_HAND, 0.8f, Vector3(0, -0.1, 0.1));

    // ========================================================================================================================
    // DANGLE
    // ========================================================================================================================
    int dangle_add_flags = kMotion_Ext_Foot_Based_Height;
    offset = Vector3(0, 0.25, 0.75);
    flags = kMotion_XYZ | dangle_add_flags;

    Global_CreateMotion(preFix + "Dangle_Left",  flags).SetDockAlign(L_HAND, 0.5f, offset);
    Global_CreateMotion(preFix + "Dangle_Right",  flags).SetDockAlign(R_HAND, 0.5f, offset);

    //offset = Vector3(0, 0.20, 0.25);
    flags = kMotion_ALL | dangle_add_flags;
    Global_CreateMotion(preFix + "Dangle_Convex_90_L",  flags).SetDockAlign(L_HAND, 0.6f, offset);
    Global_CreateMotion(preFix + "Dangle_Concave_90_L",  flags).SetDockAlign(L_HAND, 0.5f, offset);
    Global_CreateMotion(preFix + "Dangle_Convex_90_R",  flags).SetDockAlign(R_HAND, 0.6f, offset);
    Global_CreateMotion(preFix + "Dangle_Concave_90_R",  flags).SetDockAlign(R_HAND, 0.3f, offset);

    flags = kMotion_Y | dangle_add_flags;
    Global_CreateMotion(preFix + "Dangle_Left_End", flags).SetDockAlign(L_HAND, 0.6f, offset);
    Global_CreateMotion(preFix + "Dangle_Right_End", flags).SetDockAlign(R_HAND, 0.6f, offset);

    Global_CreateMotion(preFix + "Dangle_Idle", dangle_add_flags);

    // offset = Vector3(0, 0.25, 0.75);
    flags = kMotion_YZR | dangle_add_flags;
    Global_CreateMotion(preFix + "Crouch_To_Dangle", flags).SetDockAlign(R_HAND, 0.7f, offset);
    Global_CreateMotion(preFix + "Crouch_Jump_128_To_Dangle", flags).SetDockAlign(L_HAND, 0.6, offset);

    flags = kMotion_YZ | dangle_add_flags;
    Global_CreateMotion(preFix + "Dangle_Climb_Up_Run", flags).SetDockAlign(L_HAND, 0.4f, Vector3(0, -0.1, 0.1));
    Global_CreateMotion(preFix + "Dangle_Climb_Up_Over_128", flags).SetDockAlign(L_HAND, 1.2f, Vector3(0, -0.1, 0.05));

    // ========================================================================================================================
    // HANG
    // ========================================================================================================================

    flags = kMotion_YZ | kMotion_Ext_Foot_Based_Height;
    // Climb Hang
    Global_CreateMotion(preFix + "Stand_Climb_Up_256_Hang", flags, kMotion_ALL, 30).SetDockAlign(L_HAND, 0.8f, Vector3(0, 0.16, 0.3));
    Global_CreateMotion(preFix + "Stand_Climb_Up_384_Hang", flags, kMotion_ALL, 30).SetDockAlign(L_HAND, 0.8f, Vector3(0, 0.18, 0.27));
    Global_CreateMotion(preFix + "Run_Climb_Up_256_Hang", flags, kMotion_ALL, 30).SetDockAlign(L_HAND, 0.8f, Vector3(0, 0.16, 0.3));
    Global_CreateMotion(preFix + "Run_Climb_Up_384_Hang", flags, kMotion_ALL, 30).SetDockAlign(L_HAND, 0.8f, Vector3(0, 0.1, 0.24));

    offset = Vector3(0, 0.15, 0.25);
    flags = kMotion_X | kMotion_Ext_Foot_Based_Height;

    Global_CreateMotion(preFix + "Hang_Left", flags).SetDockAlign(L_HAND, 0.5f, offset);
    Global_CreateMotion(preFix + "Hang_Right", flags).SetDockAlign(R_HAND, 0.5f, offset);

    flags = kMotion_XZR | kMotion_Ext_Foot_Based_Height;
    offset = Vector3(0, 0.15, 0.75);
    Global_CreateMotion(preFix + "Hang_Left_Convex", flags).SetDockAlign(L_HAND, 0.8f, offset);
    Global_CreateMotion(preFix + "Hang_Right_Convex", flags).SetDockAlign(R_HAND, 0.8f, offset);

    offset = Vector3(0, 0.15, 0.5);
    Global_CreateMotion(preFix + "Hang_Left_Concave", flags).SetDockAlign(L_HAND, 0.4f, offset);
    Global_CreateMotion(preFix + "Hang_Right_Concave", flags).SetDockAlign(R_HAND, 0.4f, offset);

    flags = kMotion_Y | kMotion_Ext_Foot_Based_Height;
    offset = Vector3(0, 0.15, 0.4);
    Global_CreateMotion(preFix + "Hang_Left_End", flags).SetDockAlign(L_HAND, 0.6f, offset);
    Global_CreateMotion(preFix + "Hang_Right_End", flags).SetDockAlign(R_HAND, 0.6f, offset);

    Global_CreateMotion(preFix + "Dangle_To_Hang", flags);

    flags = kMotion_YZ | kMotion_Ext_Foot_Based_Height;
    Global_CreateMotion(preFix + "Hang_Climb_Up_Run", flags).SetDockAlign(L_HAND, 0.4f, Vector3(0, -0.1, 0.1));
    Global_CreateMotion(preFix + "Hang_Climb_Up_Over_128", flags).SetDockAlign(L_HAND, 1.2f, Vector3(0, -0.1, 0.05));
    Global_CreateMotion(preFix + "Hang_Jump_Over_Fall", flags).SetDockAlign(L_HAND, 0.4f, Vector3(0, -0.1, 0.1));
    Global_CreateMotion(preFix + "Hang_Jump_Over_128", flags).SetDockAlign(L_HAND, 0.4f, Vector3(0, -0.1, 0.1));


    flags = kMotion_YZR | kMotion_Ext_Foot_Based_Height;
    offset = Vector3(0, 0.1, 0.2);
    Global_CreateMotion(preFix + "Crouch_To_Hang", flags).SetDockAlign(R_HAND, 0.7f, offset);

    offset = Vector3(0, 0.0, 0.0);
    Global_CreateMotion(preFix + "Crouch_Jump_128_To_Hang", flags).SetDockAlign(L_HAND, 0.6, offset);


    preFix = "BM_Movement/";
    Global_CreateMotion(preFix + "Cover_Run", kMotion_Z, kMotion_Z, -1, true);
    Global_AddAnimation(preFix + "Crouch_Idle");
    Global_AddAnimation(preFix + "Cover_Idle");

    preFix = "BM_Crouch_Turns/";
    Global_CreateMotion(preFix + "Turn_Right_90", kMotion_XZR, kMotion_XZR, 12);
    Global_CreateMotion(preFix + "Turn_Right_180", kMotion_XZR, kMotion_XZR, 20);
    Global_CreateMotion(preFix + "Turn_Left_90", kMotion_XZR, kMotion_XZR, 12);
}

void Create_BM_Motions()
{
    AssignMotionRig("Models/batman.mdl");

    String preFix = "BM_Movement/";
    Global_CreateMotion(preFix + "Turn_Right_90", kMotion_R, kMotion_R, 16);
    Global_CreateMotion(preFix + "Turn_Right_180", kMotion_R, kMotion_R, 25);
    Global_CreateMotion(preFix + "Turn_Left_90", kMotion_R, kMotion_R, 14);
    Global_CreateMotion(preFix + "Walk", kMotion_Z, kMotion_Z, -1, true);

    Global_CreateMotion(preFix + "Stand_To_Walk_Right_90", kMotion_XZR, kMotion_ALL, 17);
    Global_CreateMotion(preFix + "Stand_To_Walk_Right_180", kMotion_XZR, kMotion_ALL, 17);
    Global_CreateMotion(preFix + "Stand_To_Run", kMotion_Z, kMotion_ALL, 15);
    Global_CreateMotion(preFix + "Stand_To_Run_Right_90", kMotion_XZR, kMotion_ALL, 17);
    Global_CreateMotion(preFix + "Stand_To_Run_Right_180", kMotion_XZR, kMotion_ALL, 25);

    preFix = "BM_Movement/";
    Global_CreateMotion(preFix + "Run", kMotion_Z, kMotion_Z, -1, true);
    Global_CreateMotion(preFix + "Run_Right_Passing_To_Stand");
    Global_CreateMotion(preFix + "Run_Right_Passing_To_Run_Right_180", kMotion_XZR, kMotion_ZR, 20);
    Global_AddAnimation(preFix + "Stand_Idle");
    Global_AddAnimation(preFix + "Fall");
    Global_AddAnimation(preFix + "Land");
    Global_CreateMotion(preFix + "Cover_Transition", kMotion_R, kMotion_R);

    preFix = "BM_Combat/";
    Global_CreateMotion(preFix + "Evade_Forward_03");

    if (game_type == 1)
        Create_BM_ClimbAnimations();
}

void Add_BM_AnimationTriggers()
{
    String preFix = "BM_Combat/";
    AddAnimationTrigger(preFix + "Evade_Forward_03", 48, READY_TO_FIGHT);
    AddAnimationTrigger(preFix + "Evade_Back_01", 48, READY_TO_FIGHT);
    AddAnimationTrigger(preFix + "Evade_Left_01", 48, READY_TO_FIGHT);
    AddAnimationTrigger(preFix + "Evade_Right_01", 48, READY_TO_FIGHT);

    preFix = "BM_Movement/";
    AddStringAnimationTrigger(preFix + "Walk", 11, FOOT_STEP, R_FOOT);
    AddStringAnimationTrigger(preFix + "Walk", 24, FOOT_STEP, L_FOOT);
    AddStringAnimationTrigger(preFix + "Turn_Right_90", 11, FOOT_STEP, R_FOOT);
    AddStringAnimationTrigger(preFix + "Turn_Right_90", 15, FOOT_STEP, L_FOOT);
    AddStringAnimationTrigger(preFix + "Turn_Right_180", 13, FOOT_STEP, R_FOOT);
    AddStringAnimationTrigger(preFix + "Turn_Right_180", 20, FOOT_STEP, L_FOOT);
    AddStringAnimationTrigger(preFix + "Turn_Left_90", 13, FOOT_STEP, L_FOOT);
    AddStringAnimationTrigger(preFix + "Turn_Left_90", 20, FOOT_STEP, R_FOOT);

    if (game_type == 1)
    {
        preFix = "BM_Climb/";
        Vector3 offset = Vector3(0, -2.5f, 0);
        //TranslateAnimation(GetAnimationName(preFix + "Dangle_Idle"), offset);
        //TranslateAnimation(GetAnimationName(preFix + "Dangle_Left"), offset);
        //TranslateAnimation(GetAnimationName(preFix + "Dangle_Left_1"), offset);
        //TranslateAnimation(GetAnimationName(preFix + "Dangle_Left_End"), offset);
        //TranslateAnimation(GetAnimationName(preFix + "Dangle_Left_End_1"), offset);

        //TranslateAnimation(GetAnimationName(preFix + "Dangle_Right"), offset);
        //TranslateAnimation(GetAnimationName(preFix + "Dangle_Right_1"), offset);
        //TranslateAnimation(GetAnimationName(preFix + "Dangle_Right_End"), offset);
        //TranslateAnimation(GetAnimationName(preFix + "Dangle_Right_End_1"), offset);
    }
}


// ==============================================
//
//    Bruce Class
//
// ==============================================

// -- non cost
float BRUCE_TRANSITION_DIST = 0.0f;

class BruceStandState : PlayerStandState
{
    BruceStandState(Character@ c)
    {
        super(c);
        animations.Push(GetAnimationName("BM_Movement/Stand_Idle"));
        flags = FLAGS_ATTACK;
    }
};

class BruceTurnState : PlayerTurnState
{
    BruceTurnState(Character@ c)
    {
        super(c);
        AddMotion("BW_Movement/Turn_Right_90");
        AddMotion("BW_Movement/Turn_Right_180");
        AddMotion("BW_Movement/Turn_Left_90");
    }
};

class BruceWalkState : PlayerWalkState
{
    BruceWalkState(Character@ c)
    {
        super(c);
        SetMotion("BW_Movement/Walk_Forward");
    }
};

class BruceRunState : PlayerRunState
{
    BruceRunState(Character@ c)
    {
        super(c);
        SetMotion("BM_Movement/Run_Forward");
    }
};

class BruceRunToStandState : PlayerRunToStandState
{
    BruceRunToStandState(Character@ c)
    {
        super(c);
        SetMotion("BM_Movement/Run_Right_Passing_To_Stand");
    }
};

class BruceRunTurn180State : PlayerRunTurn180State
{
    BruceRunTurn180State(Character@ c)
    {
        super(c);
        SetMotion("BM_Movement/Run_Right_Passing_To_Run_Right_180");
    }
};

class BruceEvadeState : PlayerEvadeState
{
    BruceEvadeState(Character@ c)
    {
        super(c);
        String prefix = "BM_Combat/";
        AddMotion(prefix + "Evade_Forward_01");
        AddMotion(prefix + "Evade_Right_01");
        AddMotion(prefix + "Evade_Back_01");
        AddMotion(prefix + "Evade_Left_01");
    }
};

class BruceAttackState : PlayerAttackState
{
    BruceAttackState(Character@ c)
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


class BruceCounterState : PlayerCounterState
{
    BruceCounterState(Character@ c)
    {
        super(c);
        AddBW_Counter_Animations("BW_TG_Counter/", "BM_TG_Counter/", true);
    }
};

class BruceHitState : PlayerHitState
{
    BruceHitState(Character@ c)
    {
        super(c);
        String hitPrefix = "BM_HitReaction/";
        AddMotion(hitPrefix + "HitReaction_Face_Right");
        AddMotion(hitPrefix + "Hit_Reaction_SideLeft");
        AddMotion(hitPrefix + "HitReaction_Back");
        AddMotion(hitPrefix + "Hit_Reaction_SideRight");
    }
};

class BruceDeadState : PlayerDeadState
{
    BruceDeadState(Character@ c)
    {
        super(c);
        String prefix = "BM_Death_Primers/";
        AddMotion(prefix + "Death_Front");
        AddMotion(prefix + "Death_Side_Left");
        AddMotion(prefix + "Death_Back");
        AddMotion(prefix + "Death_Side_Right");
    }
};

class BruceBeatDownEndState : PlayerBeatDownEndState
{
    BruceBeatDownEndState(Character@ c)
    {
        super(c);
        String preFix = "BM_TG_Beatdown/";
        AddMotion(preFix + "Beatdown_Strike_End_01");
        AddMotion(preFix + "Beatdown_Strike_End_02");
        AddMotion(preFix + "Beatdown_Strike_End_03");
        AddMotion(preFix + "Beatdown_Strike_End_04");
    }
};

class BruceBeatDownHitState : PlayerBeatDownHitState
{
    BruceBeatDownHitState(Character@ c)
    {
        super(c);
        String preFix = "BM_Attack/";
        AddMotion(preFix + "Beatdown_Test_01");
        AddMotion(preFix + "Beatdown_Test_02");
        AddMotion(preFix + "Beatdown_Test_03");
        AddMotion(preFix + "Beatdown_Test_04");
        AddMotion(preFix + "Beatdown_Test_05");
        AddMotion(preFix + "Beatdown_Test_06");
    }

    bool IsTransitionNeeded(float curDist)
    {
        return curDist > BRUCE_TRANSITION_DIST + 0.5f;
    }
};

class BruceTransitionState : PlayerTransitionState
{
    BruceTransitionState(Character@ c)
    {
        super(c);
        SetMotion("BM_Combat/Into_Takedown");
        BRUCE_TRANSITION_DIST = motion.endDistance;
        Print("Bruce-Transition Dist=" + BRUCE_TRANSITION_DIST);
    }
};

class BruceSlideInState : PlayerSlideInState
{
    BruceSlideInState(Character@ c)
    {
        super(c);
        SetMotion("BM_Climb/Slide_Floor_In");
    }
};

class BruceSlideOutState : PlayerSlideOutState
{
    BruceSlideOutState(Character@ c)
    {
        super(c);
        String preFix = "BM_Climb/";
        AddMotion(preFix + "Slide_Floor_Stop");
        AddMotion(preFix + "Slide_Floor_Out");
    }
};

class BruceCrouchState : PlayerCrouchState
{
    BruceCrouchState(Character@ c)
    {
        super(c);
        SetMotion("BM_Movement/Crouch_Idle");
    }
};

class BruceCrouchTurnState : PlayerCrouchTurnState
{
    BruceCrouchTurnState(Character@ c)
    {
        super(c);
        AddMotion("BM_Crouch_Turns/Turn_Right_90");
        AddMotion("BM_Crouch_Turns/Turn_Right_180");
        AddMotion("BM_Crouch_Turns/Turn_Left_90");
    }
};

class BruceCrouchMoveState : PlayerCrouchMoveState
{
    BruceCrouchMoveState(Character@ c)
    {
        super(c);
        SetMotion("BM_Movement/Cover_Run");
        animSpeed = 0.5f;
    }
};

class BruceFallState : PlayerFallState
{
    BruceFallState(Character@ c)
    {
        super(c);
        SetMotion("BM_Movement/Fall");
    }
};

class BruceLandState : PlayerLandState
{
    BruceLandState(Character@ c)
    {
        super(c);
        SetMotion("BM_Movement/Land");
    }
};

class BruceCoverState : PlayerCoverState
{
    BruceCoverState(Character@ c)
    {
        super(c);
        SetMotion("BM_Movement/Cover_Idle");
    }
};

class BruceCoverRunState : PlayerCoverRunState
{
    BruceCoverRunState(Character@ c)
    {
        super(c);
        SetMotion("BM_Movement/Cover_Run");
        animSpeed = 0.5f;
    }
};

class BruceCoverTransitionState : PlayerCoverTransitionState
{
    BruceCoverTransitionState(Character@ c)
    {
        super(c);
        SetMotion("BM_Movement/Cover_Transition");
    }
};

class BruceClimbOverState : PlayerClimbOverState
{
    BruceClimbOverState(Character@ c)
    {
        super(c);
        AddMotion("BM_Climb/Stand_Climb_Over_128");
        AddMotion("BM_Climb/Run_Climb_Over_128");
        targetOffsets.Push(Vector3(0, 0, -1.9));
        targetOffsets.Push(Vector3(0, 0, -4.0));
    }
};

class BruceClimbUpState : PlayerClimbUpState
{
    BruceClimbUpState(Character@ c)
    {
        super(c);
        AddMotion("BM_Climb/Stand_Climb_Up_128");
        AddMotion("BM_Climb/Stand_Climb_Up_256");
        AddMotion("BM_Climb/Stand_Climb_Up_384");
        AddMotion("BM_Climb/Run_Climb_Up_128");
        AddMotion("BM_Climb/Run_Climb_Up_256");
        AddMotion("BM_Climb/Run_Climb_Up_384");

        targetOffsets.Push(Vector3(0, 0, -2.75));
        targetOffsets.Push(Vector3(0, 0, -1.43629));
        targetOffsets.Push(Vector3(0, 0, -1.8));

        targetOffsets.Push(Vector3(0, 0, -6.0));
        targetOffsets.Push(Vector3(0, 0, -6.4));
        targetOffsets.Push(Vector3(0, 0, -6.452));
    }
};

class BruceRailUpState : PlayerRailUpState
{
    BruceRailUpState(Character@ c)
    {
        super(c);
        AddMotion("BM_Railing/Railing_Climb_Up");
        AddMotion("BM_Railing/Stand_Climb_Onto_256_Railing");
        AddMotion("BM_Railing/Stand_Climb_Onto_384_Railing");
        AddMotion("BM_Railing/Railing_Climb_Up");
        AddMotion("BM_Railing/Run_Climb_Onto_256_Railing");
        AddMotion("BM_Railing/Run_Climb_Onto_384_Railing");

        targetOffsets.Push(Vector3(0, 0, -1.5));
        targetOffsets.Push(Vector3(0, 0, -1.5));
        targetOffsets.Push(Vector3(0, 0, -1.5));

        targetOffsets.Push(Vector3(0, 0, -1.5));
        targetOffsets.Push(Vector3(0, 0, -6.4));
        targetOffsets.Push(Vector3(0, 0, -6.452));
    }
};

class BruceRailIdleState : PlayerRailIdleState
{
    BruceRailIdleState(Character@ c)
    {
        super(c);
        SetMotion("BM_Railing/Railing_Idle");
    }
};

class BruceRailTurnState : PlayerRailTurnState
{
    BruceRailTurnState(Character@ c)
    {
        super(c);
        AddMotion("BM_Railing/Railing_Idle_Turn_180_Right");
        AddMotion("BM_Railing/Railing_Idle_Turn_180_Left");
    }
};

class BruceRailDownState : PlayerRailDownState
{
    BruceRailDownState(Character@ c)
    {
        super(c);
        AddMotion("BM_Railing/Railing_Climb_Down_Forward");
        AddMotion("BM_Railing/Railing_Jump_To_Fall");
    }
};

class BruceRailFwdIdleState : PlayerRailFwdIdleState
{
    BruceRailFwdIdleState(Character@ c)
    {
        super(c);
        SetMotion("BM_Railing/Railing_Run_Forward_Idle");
    }
};


class BruceRailRunForwardState : PlayerRailRunForwardState
{
    BruceRailRunForwardState(Character@ c)
    {
        super(c);
        SetMotion("BM_Railing/Railing_Run_Forward");
    }
};

class BruceRailRunTurn180State : PlayerRailTurn180State
{
    BruceRailRunTurn180State(Character@ c)
    {
        super(c);
        SetMotion("BM_Railing/Stand_To_Walk_Right_180");
    }
};

class BruceHangUpState : PlayerRailUpState
{
    BruceHangUpState(Character@ c)
    {
        super(c);
        AddMotion("BM_Climb/Stand_Climb_Up_128_Hang");
        AddMotion("BM_Climb/Stand_Climb_Up_256_Hang");
        AddMotion("BM_Climb/Stand_Climb_Up_384_Hang");
        AddMotion("BM_Climb/Run_Climb_Up_128_Hang");
        AddMotion("BM_Climb/Run_Climb_Up_256_Hang");
        AddMotion("BM_Climb/Run_Climb_Up_384_Hang");

        targetOffsets.Push(Vector3(0, 0, -1.5));
        targetOffsets.Push(Vector3(0, 0, -1.5));
        targetOffsets.Push(Vector3(0, 0, -1.5));

        targetOffsets.Push(Vector3(0, 0, -1.5));
        targetOffsets.Push(Vector3(0, 0, -6.4));
        targetOffsets.Push(Vector3(0, 0, -6.452));
    }
};

class BruceHangIdleState : PlayerHangIdleState
{
    BruceHangIdleState(Character@ c)
    {
        super(c);
        SetMotion("BM_Climb/Hang_Idle");
    }
};

class Bruce : Player
{
    Bruce()
    {
        super();
        walkAlignAnimation = GetAnimationName("BW_Movement/Walk_Forward");
    }

    void AddStates()
    {
        stateMachine.AddState(BruceStandState(this));
        stateMachine.AddState(BruceTurnState(this));
        stateMachine.AddState(BruceWalkState(this));
        stateMachine.AddState(BruceRunState(this));
        stateMachine.AddState(BruceRunToStandState(this));
        stateMachine.AddState(BruceRunTurn180State(this));
        stateMachine.AddState(BruceEvadeState(this));
        stateMachine.AddState(CharacterAlignState(this));
        stateMachine.AddState(AnimationTestState(this));

        if (game_type == 0)
        {
            stateMachine.AddState(BruceAttackState(this));
            stateMachine.AddState(BruceCounterState(this));
            stateMachine.AddState(BruceHitState(this));
            stateMachine.AddState(BruceDeadState(this));
            stateMachine.AddState(BruceBeatDownHitState(this));
            stateMachine.AddState(BruceBeatDownEndState(this));
            stateMachine.AddState(BruceTransitionState(this));
        }
        else if (game_type == 1)
        {
            stateMachine.AddState(BruceSlideInState(this));
            stateMachine.AddState(BruceSlideOutState(this));
            stateMachine.AddState(BruceCrouchState(this));
            stateMachine.AddState(BruceCrouchTurnState(this));
            stateMachine.AddState(BruceCrouchMoveState(this));
            stateMachine.AddState(BruceFallState(this));
            stateMachine.AddState(BruceLandState(this));
            stateMachine.AddState(BruceCoverState(this));
            stateMachine.AddState(BruceCoverRunState(this));
            stateMachine.AddState(BruceCoverTransitionState(this));
            stateMachine.AddState(BruceClimbOverState(this));
            stateMachine.AddState(BruceClimbUpState(this));
            // rail states
            stateMachine.AddState(BruceRailUpState(this));
            stateMachine.AddState(BruceRailIdleState(this));
            stateMachine.AddState(BruceRailTurnState(this));
            stateMachine.AddState(BruceRailDownState(this));
            stateMachine.AddState(BruceRailFwdIdleState(this));
            stateMachine.AddState(BruceRailRunForwardState(this));
            stateMachine.AddState(BruceRailRunTurn180State(this));
            stateMachine.AddState(BruceHangUpState(this));
            stateMachine.AddState(BruceHangIdleState(this));
        }
    }
};

void CreateBruceCombatMotions()
{
    String preFix = "BM_HitReaction/";
    Global_CreateMotion(preFix + "HitReaction_Back"); // back attacked
    Global_CreateMotion(preFix + "HitReaction_Face_Right"); // front punched
    Global_CreateMotion(preFix + "Hit_Reaction_SideLeft"); // left attacked
    Global_CreateMotion(preFix + "Hit_Reaction_SideRight"); // right attacked

    Global_CreateMotion_InFolder("BW_Attack/");
    Global_CreateMotion_InFolder("BW_TG_Counter/");

    preFix = "BM_TG_Counter/";
    Global_CreateMotion(preFix + "Double_Counter_2ThugsA", kMotion_XZR, kMotion_XZR, -1, false, 90);
    Global_CreateMotion(preFix + "Double_Counter_2ThugsB", kMotion_XZR, kMotion_XZR, -1, false, 90);
    Global_CreateMotion(preFix + "Double_Counter_2ThugsD", kMotion_XZR, kMotion_XZR, -1, false, -90);
    Global_CreateMotion(preFix + "Double_Counter_2ThugsE");
    Global_CreateMotion(preFix + "Double_Counter_2ThugsF");
    Global_CreateMotion(preFix + "Double_Counter_2ThugsG");
    Global_CreateMotion(preFix + "Double_Counter_2ThugsH");
    Global_CreateMotion(preFix + "Double_Counter_3ThugsB", kMotion_XZR, kMotion_XZR, -1, false, -90);
    Global_CreateMotion(preFix + "Double_Counter_3ThugsC", kMotion_XZR, kMotion_XZR, -1, false, -90);

    preFix = "BM_Death_Primers/";
    Global_CreateMotion(preFix + "Death_Front");
    Global_CreateMotion(preFix + "Death_Back");
    Global_CreateMotion(preFix + "Death_Side_Left");
    Global_CreateMotion(preFix + "Death_Side_Right");

    preFix = "BM_Attack/";
    Global_CreateMotion(preFix + "Beatdown_Test_01");
    Global_CreateMotion(preFix + "Beatdown_Test_02");
    Global_CreateMotion(preFix + "Beatdown_Test_03");
    Global_CreateMotion(preFix + "Beatdown_Test_04");
    Global_CreateMotion(preFix + "Beatdown_Test_05");
    Global_CreateMotion(preFix + "Beatdown_Test_06");

    preFix = "BM_TG_Beatdown/";
    Global_CreateMotion(preFix + "Beatdown_Strike_End_01");
    Global_CreateMotion(preFix + "Beatdown_Strike_End_02");
    Global_CreateMotion(preFix + "Beatdown_Strike_End_03");
    Global_CreateMotion(preFix + "Beatdown_Strike_End_04");
}

void CreateBruceClimbAnimations()
{
    String preFix = "BM_Climb/";
    Global_CreateMotion(preFix + "Slide_Floor_In", kMotion_Z);
    Global_CreateMotion(preFix + "Slide_Floor_Out", kMotion_Z);
    Global_CreateMotion(preFix + "Slide_Floor_Stop");
    Motion@ m = Global_CreateMotion(preFix + "Run_Climb_Over_128", kMotion_Z);
    m.dockAlignTime = 0.5f;
    m.dockAlignBoneName = L_HAND;
    m.dockAlignOffset = Vector3(0, -0.1, 0);

    @m = Global_CreateMotion(preFix + "Stand_Climb_Over_128", kMotion_Z);
    m.dockAlignTime = 0.5f;
    m.dockAlignBoneName = L_HAND;
    m.dockAlignOffset = Vector3(0, -0.1, 0);

    Global_CreateMotion(preFix + "Stand_Climb_Up_128", kMotion_YZ);
    @m = Global_CreateMotion(preFix + "Run_Climb_Up_128", kMotion_YZ);
    m.dockAlignTime = 0.35f;
    m.dockAlignBoneName = L_FOOT;
    m.dockAlignOffset = Vector3(0, -0.1, 0.2);

    Global_CreateMotion(preFix + "Stand_Climb_Up_256", kMotion_YZ);
    Global_CreateMotion(preFix + "Run_Climb_Up_256", kMotion_YZ);
    Global_CreateMotion(preFix + "Stand_Climb_Up_384", kMotion_YZ);
    Global_CreateMotion(preFix + "Run_Climb_Up_384", kMotion_YZ);

    Global_CreateMotion(preFix + "Stand_Climb_Up_256_Hang", kMotion_YZ);
    Global_CreateMotion(preFix + "Stand_Climb_Up_384_Hang", kMotion_YZ);
    Global_CreateMotion(preFix + "Run_Climb_Up_256_Hang", kMotion_YZ);
    Global_CreateMotion(preFix + "Run_Climb_Up_384_Hang", kMotion_YZ);

    Global_CreateMotion(preFix + "Hang_Climb_Up_Run", kMotion_YZ);
    Global_CreateMotion(preFix + "Hang_Climb_Up_Rail", kMotion_YZ | kMotion_Ext_Foot_Based_Height);

    Global_CreateMotion(preFix + "Stand_Climb_Up_128_Hang", kMotion_YZ);
    Global_CreateMotion(preFix + "Stand_Climb_Up_256_Hang", kMotion_YZ);
    Global_CreateMotion(preFix + "Stand_Climb_Up_384_Hang", kMotion_YZ);

    Global_CreateMotion(preFix + "Run_Climb_Up_128_Hang", kMotion_YZ);
    Global_CreateMotion(preFix + "Run_Climb_Up_256_Hang", kMotion_YZ);
    Global_CreateMotion(preFix + "Run_Climb_Up_384_Hang", kMotion_YZ);

    Global_AddAnimation(preFix + "Hang_Idle");

    preFix = "BM_Movement/";
    Global_AddAnimation(preFix + "Crouch_Idle");
    // Global_CreateMotion(preFix + "Crouch_Walk_Slow", kMotion_XZR, kMotion_Z, -1, true);
    Global_CreateMotion(preFix + "Cover_Run", kMotion_Z, kMotion_Z, -1, true);
    Global_AddAnimation(preFix + "Cover_Idle");

    preFix = "BM_Crouch_Turns/";
    Global_CreateMotion(preFix + "Turn_Right_90", kMotion_R, kMotion_R, 12);
    Global_CreateMotion(preFix + "Turn_Right_180", kMotion_R, kMotion_R, 20);
    Global_CreateMotion(preFix + "Turn_Left_90", kMotion_R, kMotion_R, 12);

    preFix = "BM_Railing/";
    Global_CreateMotion(preFix + "Railing_Climb_Up", kMotion_YZ | kMotion_Ext_Foot_Based_Height);
    Global_CreateMotion(preFix + "Stand_Climb_Onto_256_Railing", kMotion_YZ | kMotion_Ext_Foot_Based_Height);
    Global_CreateMotion(preFix + "Stand_Climb_Onto_384_Railing", kMotion_YZ | kMotion_Ext_Foot_Based_Height);
    Global_CreateMotion(preFix + "Run_Climb_Onto_256_Railing", kMotion_YZ | kMotion_Ext_Foot_Based_Height);
    Global_CreateMotion(preFix + "Run_Climb_Onto_384_Railing", kMotion_YZ | kMotion_Ext_Foot_Based_Height);

    Global_CreateMotion(preFix + "Railing_Climb_Down_Forward", kMotion_YZ | kMotion_Ext_Foot_Based_Height);
    Global_CreateMotion(preFix + "Railing_Jump_To_Fall", kMotion_YZ | kMotion_Ext_Foot_Based_Height);

    Global_CreateMotion(preFix + "Railing_Idle_Turn_180_Right", kMotion_XZR, kMotion_R);
    Global_CreateMotion(preFix + "Railing_Idle_Turn_180_Left", kMotion_XZR, kMotion_R);
    Global_CreateMotion(preFix + "Stand_To_Walk_Right_180");
    Global_CreateMotion(preFix + "Railing_Run_Forward", kMotion_Z, kMotion_Z, -1, true);
    Global_CreateMotion(preFix + "Railing_Run_Forward_Idle", 0);

    Global_AddAnimation(preFix + "Railing_Idle");
    Global_AddAnimation(preFix + "Railing_Run_Forward_Idle");
}

void CreateBruceMotions()
{
    AssignMotionRig("Models/bruce_w.mdl");

    String preFix = "BW_Movement/";
    Global_CreateMotion(preFix + "Turn_Right_90", kMotion_R, kMotion_R, 16);
    Global_CreateMotion(preFix + "Turn_Right_180", kMotion_R, kMotion_R, 25);
    Global_CreateMotion(preFix + "Turn_Left_90", kMotion_R, kMotion_R, 14);
    Global_CreateMotion(preFix + "Walk_Forward", kMotion_Z, kMotion_Z, -1, true);

    preFix = "BM_Movement/";
    Global_CreateMotion(preFix + "Run_Forward", kMotion_Z, kMotion_Z, -1, true);
    Global_CreateMotion(preFix + "Run_Right_Passing_To_Stand");
    Global_CreateMotion(preFix + "Run_Right_Passing_To_Run_Right_180", kMotion_ZR, kMotion_ZR, 28);
    Global_AddAnimation(preFix + "Stand_Idle");
    Global_AddAnimation(preFix + "Fall");
    Global_AddAnimation(preFix + "Land");
    Global_CreateMotion(preFix + "Cover_Transition", kMotion_R, kMotion_R);

    preFix = "BM_Combat/";
    Global_CreateMotion(preFix + "Into_Takedown");
    Global_CreateMotion(preFix + "Evade_Forward_01");
    Global_CreateMotion(preFix + "Evade_Back_01");
    Global_CreateMotion(preFix + "Evade_Left_01");
    Global_CreateMotion(preFix + "Evade_Right_01");

    if (game_type == 0)
        CreateBruceCombatMotions();
    else if (game_type == 1)
        CreateBruceClimbAnimations();
}

void AddBruceCombatAnimationTriggers()
{
    String preFix = "BM_Attack/";
    int beat_impact_frame = 4;
    AddStringAnimationTrigger(preFix + "Beatdown_Test_01", beat_impact_frame, IMPACT, L_HAND);
    AddStringAnimationTrigger(preFix + "Beatdown_Test_02", beat_impact_frame, IMPACT, R_HAND);
    AddStringAnimationTrigger(preFix + "Beatdown_Test_03", beat_impact_frame, IMPACT, L_HAND);
    AddStringAnimationTrigger(preFix + "Beatdown_Test_04", beat_impact_frame, IMPACT, R_HAND);
    AddStringAnimationTrigger(preFix + "Beatdown_Test_05", beat_impact_frame, IMPACT, R_HAND);
    AddStringAnimationTrigger(preFix + "Beatdown_Test_06", beat_impact_frame, IMPACT, R_HAND);

    // ===========================================================================
    //
    //   COUNTER TRIGGERS
    //
    // ===========================================================================
    preFix = "BM_TG_Beatdown/";
    AddStringAnimationTrigger(preFix + "Beatdown_Strike_End_01", 16, IMPACT, R_HAND);
    AddStringAnimationTrigger(preFix + "Beatdown_Strike_End_02", 30, IMPACT, HEAD);
    AddStringAnimationTrigger(preFix + "Beatdown_Strike_End_03", 24, IMPACT, R_FOOT);
    AddStringAnimationTrigger(preFix + "Beatdown_Strike_End_04", 28, IMPACT, L_CALF);

    preFix = "BW_TG_Counter/";
    String animName = preFix + "Counter_Arm_Back_01";
    AddStringAnimationTrigger(animName, 9, COMBAT_SOUND, R_ARM);
    AddStringAnimationTrigger(animName, 38, COMBAT_SOUND, R_ARM);
    AddAnimationTrigger(animName, 40, READY_TO_FIGHT);

    animName = preFix + "Counter_Arm_Back_02";
    AddStringAnimationTrigger(animName, 8, COMBAT_SOUND, R_HAND);
    AddStringAnimationTrigger(animName, 41, COMBAT_SOUND, R_FOOT);
    AddAnimationTrigger(animName, 43, READY_TO_FIGHT);

    animName = preFix + "Counter_Arm_Back_03";
    AddStringAnimationTrigger(animName, 6, COMBAT_SOUND, R_ARM);
    AddStringAnimationTrigger(animName, 17, COMBAT_SOUND, R_ARM);
    AddStringAnimationTrigger(animName, 33, COMBAT_SOUND, L_FOOT);
    AddAnimationTrigger(animName, 35, READY_TO_FIGHT);

    animName = preFix + "Counter_Arm_Back_04";
    AddStringAnimationTrigger(animName, 14, COMBAT_SOUND, R_HAND);
    AddStringAnimationTrigger(animName, 28, COMBAT_SOUND, R_CALF);
    AddAnimationTrigger(animName, 40, READY_TO_FIGHT);

    animName = preFix + "Counter_Arm_Back_Weak_01";
    AddStringAnimationTrigger(animName, 11, COMBAT_SOUND, R_ARM);
    AddStringAnimationTrigger(animName, 25, COMBAT_SOUND, R_ARM);
    AddAnimationTrigger(animName, 27, READY_TO_FIGHT);

    animName = preFix + "Counter_Arm_Front_01";
    AddStringAnimationTrigger(animName, 9, COMBAT_SOUND, R_HAND);
    AddStringAnimationTrigger(animName, 17, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 34, COMBAT_SOUND, R_FOOT);
    AddAnimationTrigger(animName, 36, READY_TO_FIGHT);

    animName = preFix + "Counter_Arm_Front_02";
    AddStringAnimationTrigger(animName, 9, COMBAT_SOUND, R_ARM);
    AddStringAnimationTrigger(animName, 22, COMBAT_SOUND, R_ARM);
    AddStringAnimationTrigger(animName, 45, COMBAT_SOUND, R_HAND);
    AddAnimationTrigger(animName, 47, READY_TO_FIGHT);

    animName = preFix + "Counter_Arm_Front_03";
    AddStringAnimationTrigger(animName, 9, COMBAT_SOUND, R_ARM);
    AddStringAnimationTrigger(animName, 39, COMBAT_SOUND, R_HAND);
    AddAnimationTrigger(animName, 41, READY_TO_FIGHT);

    animName = preFix + "Counter_Arm_Front_04";
    AddStringAnimationTrigger(animName, 12, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 34, COMBAT_SOUND, R_ARM);
    AddAnimationTrigger(animName, 41, READY_TO_FIGHT);

    animName = preFix + "Counter_Arm_Front_05";
    AddStringAnimationTrigger(animName, 7, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 26, COMBAT_SOUND, R_HAND);
    AddStringAnimationTrigger(animName, 43, COMBAT_SOUND, L_HAND);
    AddAnimationTrigger(animName, 45, READY_TO_FIGHT);

    animName = preFix + "Counter_Arm_Front_06";
    AddStringAnimationTrigger(animName, 5, COMBAT_SOUND, R_ARM);
    AddStringAnimationTrigger(animName, 18, COMBAT_SOUND, R_FOOT);
    AddStringAnimationTrigger(animName, 38, COMBAT_SOUND, L_HAND);
    AddAnimationTrigger(animName, 40, READY_TO_FIGHT);

    animName = preFix + "Counter_Arm_Front_07";
    AddStringAnimationTrigger(animName, 6, COMBAT_SOUND, R_HAND);
    AddStringAnimationTrigger(animName, 24, COMBAT_SOUND, L_HAND);
    AddAnimationTrigger(animName, 26, READY_TO_FIGHT);

    animName = preFix + "Counter_Arm_Front_08";
    AddStringAnimationTrigger(animName, 4, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 11, COMBAT_SOUND, R_HAND);
    AddStringAnimationTrigger(animName, 30, COMBAT_SOUND, R_ARM);
    AddAnimationTrigger(animName, 32, READY_TO_FIGHT);

    animName = preFix + "Counter_Arm_Front_09";
    AddStringAnimationTrigger(animName, 6, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 22, COMBAT_SOUND, L_ARM);
    AddStringAnimationTrigger(animName, 39, COMBAT_SOUND, R_HAND);
    AddAnimationTrigger(animName, 41, READY_TO_FIGHT);

    animName = preFix + "Counter_Arm_Front_10";
    AddStringAnimationTrigger(animName, 10, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 23, COMBAT_SOUND, L_FOOT);
    AddAnimationTrigger(animName, 25, READY_TO_FIGHT);

    animName = preFix + "Counter_Arm_Front_Weak_02";
    AddStringAnimationTrigger(animName, 4, COMBAT_SOUND, L_ARM);
    AddStringAnimationTrigger(animName, 9, COMBAT_SOUND, R_HAND);
    AddStringAnimationTrigger(animName, 21, COMBAT_SOUND, L_HAND);
    AddAnimationTrigger(animName, 23, READY_TO_FIGHT);

    animName = preFix + "Counter_Leg_Back_01";
    AddStringAnimationTrigger(animName, 9, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 17, COMBAT_SOUND, L_FOOT);
    AddStringAnimationTrigger(animName, 46, COMBAT_SOUND, R_ARM);
    AddAnimationTrigger(animName, 48, READY_TO_FIGHT);

    animName = preFix + "Counter_Leg_Back_02";
    AddStringAnimationTrigger(animName, 7, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 15, COMBAT_SOUND, R_ARM);
    AddStringAnimationTrigger(animName, 46, COMBAT_SOUND, L_CALF);
    AddAnimationTrigger(animName, 48, READY_TO_FIGHT);

    animName = preFix + "Counter_Leg_Back_Weak_01";
    AddStringAnimationTrigger(animName, 7, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 30, COMBAT_SOUND, R_ARM);
    AddAnimationTrigger(animName, 32, READY_TO_FIGHT);

    animName = preFix + "Counter_Leg_Front_01";
    AddStringAnimationTrigger(animName, 11, COMBAT_SOUND, L_FOOT);
    AddStringAnimationTrigger(animName, 30, COMBAT_SOUND, L_FOOT);
    AddAnimationTrigger(animName, 32, READY_TO_FIGHT);

    animName = preFix + "Counter_Leg_Front_02";
    AddStringAnimationTrigger(animName, 6, COMBAT_SOUND, R_HAND);
    AddStringAnimationTrigger(animName, 15, COMBAT_SOUND, R_ARM);
    AddStringAnimationTrigger(animName, 42, COMBAT_SOUND, L_CALF);
    AddAnimationTrigger(animName, 44, READY_TO_FIGHT);

    animName = preFix + "Counter_Leg_Front_03";
    AddStringAnimationTrigger(animName, 3, COMBAT_SOUND, R_ARM);
    AddStringAnimationTrigger(animName, 22, COMBAT_SOUND, L_HAND);
    AddAnimationTrigger(animName, 24, READY_TO_FIGHT);

    animName = preFix + "Counter_Leg_Front_04";
    AddStringAnimationTrigger(animName, 7, COMBAT_SOUND, L_FOOT);
    AddStringAnimationTrigger(animName, 30, COMBAT_SOUND, R_FOOT);
    AddAnimationTrigger(animName, 32, READY_TO_FIGHT);

    animName = preFix + "Counter_Leg_Front_05";
    AddStringAnimationTrigger(animName, 5, COMBAT_SOUND, L_FOOT);
    AddStringAnimationTrigger(animName, 18, COMBAT_SOUND, L_FOOT);
    AddStringAnimationTrigger(animName, 38, COMBAT_SOUND, R_FOOT);
    AddAnimationTrigger(animName, 40, READY_TO_FIGHT);

    animName = preFix + "Counter_Leg_Front_06";
    AddStringAnimationTrigger(animName, 6, COMBAT_SOUND, R_HAND);
    AddStringAnimationTrigger(animName, 18, COMBAT_SOUND, L_HAND);
    AddAnimationTrigger(animName, 20, READY_TO_FIGHT);

    animName = preFix + "Counter_Leg_Front_Weak";
    AddStringAnimationTrigger(animName, 12, COMBAT_SOUND, L_FOOT);
    AddStringAnimationTrigger(animName, 18, COMBAT_SOUND, L_FOOT);
    AddAnimationTrigger(animName, 20, READY_TO_FIGHT);

    preFix = "BM_TG_Counter/";
    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsA", 12, PARTICLE, R_HAND);
    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsA", 12, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsA", 77, PARTICLE, R_HAND);
    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsA", 77, COMBAT_SOUND_LARGE, R_HAND);
    AddAnimationTrigger(preFix + "Double_Counter_2ThugsA", 79, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsB", 12, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsB", 36, COMBAT_SOUND_LARGE, L_HAND);
    AddAnimationTrigger(preFix + "Double_Counter_2ThugsB", 60, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsD", 7, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsD", 7, PARTICLE, R_HAND);
    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsD", 15, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsD", 38, PARTICLE, L_HAND);
    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsD", 38, COMBAT_SOUND_LARGE, R_HAND);
    AddAnimationTrigger(preFix + "Double_Counter_2ThugsD", 43, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsE", 21, COMBAT_SOUND, R_ARM);
    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsE", 43, COMBAT_SOUND, L_FOOT);
    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsE", 76, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsE", 83, COMBAT_SOUND_LARGE, L_HAND);
    AddAnimationTrigger(preFix + "Double_Counter_2ThugsE", 85, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsF", 26, COMBAT_SOUND_LARGE, L_FOOT);
    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsF", 26, PARTICLE, R_FOOT);
    AddAnimationTrigger(preFix + "Double_Counter_2ThugsF", 60, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsG", 23, COMBAT_SOUND_LARGE, L_HAND);
    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsG", 23, PARTICLE, R_HAND);
    AddAnimationTrigger(preFix + "Double_Counter_2ThugsG", 25, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsH", 21, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsH", 21, PARTICLE, R_HAND);
    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsH", 36, PARTICLE, L_HAND);
    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsH", 36, COMBAT_SOUND_LARGE, R_HAND);
    AddAnimationTrigger(preFix + "Double_Counter_2ThugsH", 65, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Double_Counter_3ThugsB", 27, PARTICLE, L_FOOT);
    AddStringAnimationTrigger(preFix + "Double_Counter_3ThugsB", 27, PARTICLE, R_FOOT);
    AddStringAnimationTrigger(preFix + "Double_Counter_3ThugsB", 27, COMBAT_SOUND_LARGE, R_HAND);
    AddAnimationTrigger(preFix + "Double_Counter_3ThugsB", 50, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Double_Counter_3ThugsC", 5, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(preFix + "Double_Counter_3ThugsC", 5, PARTICLE, R_HAND);
    AddStringAnimationTrigger(preFix + "Double_Counter_3ThugsC", 37, PARTICLE, L_FOOT);
    AddStringAnimationTrigger(preFix + "Double_Counter_3ThugsC", 37, COMBAT_SOUND_LARGE, R_HAND);
    AddAnimationTrigger(preFix + "Double_Counter_3ThugsC", 52, READY_TO_FIGHT);
}

void AddBruceAnimationTriggers()
{
    String preFix = "BM_Combat/";
    AddAnimationTrigger(preFix + "Evade_Forward_01", 48, READY_TO_FIGHT);
    AddAnimationTrigger(preFix + "Evade_Back_01", 48, READY_TO_FIGHT);
    AddAnimationTrigger(preFix + "Evade_Left_01", 48, READY_TO_FIGHT);
    AddAnimationTrigger(preFix + "Evade_Right_01", 48, READY_TO_FIGHT);

    preFix = "BW_Movement/";
    AddStringAnimationTrigger(preFix + "Walk_Forward", 11, FOOT_STEP, R_FOOT);
    AddStringAnimationTrigger(preFix + "Walk_Forward", 24, FOOT_STEP, L_FOOT);
    AddStringAnimationTrigger(preFix + "Turn_Right_90", 11, FOOT_STEP, R_FOOT);
    AddStringAnimationTrigger(preFix + "Turn_Right_90", 15, FOOT_STEP, L_FOOT);
    AddStringAnimationTrigger(preFix + "Turn_Right_180", 13, FOOT_STEP, R_FOOT);
    AddStringAnimationTrigger(preFix + "Turn_Right_180", 20, FOOT_STEP, L_FOOT);
    AddStringAnimationTrigger(preFix + "Turn_Left_90", 13, FOOT_STEP, L_FOOT);
    AddStringAnimationTrigger(preFix + "Turn_Left_90", 20, FOOT_STEP, R_FOOT);

    if (game_type == 0)
        AddBruceCombatAnimationTriggers();
}


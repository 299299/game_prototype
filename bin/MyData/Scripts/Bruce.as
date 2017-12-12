// ==============================================
//
//    Bruce Class
//
// ==============================================

// -- non cost
float BRUCE_TRANSITION_DIST = 0.0f;
const String BRUCE_MOVEMENT_GROUP = "BM_Movement/";
Array<Motion@> bruce_counter_arm_front_motions;
Array<Motion@> bruce_counter_arm_back_motions;
Array<Motion@> bruce_counter_leg_front_motions;
Array<Motion@> bruce_counter_leg_back_motions;
Array<Motion@> bruce_counter_double_motions;
Array<Motion@> bruce_counter_triple_motions;
Array<Motion@> bruce_counter_environment_motions;

class BruceStandState : PlayerStandState
{
    BruceStandState(Character@ c)
    {
        super(c);
        AddMotion(BRUCE_MOVEMENT_GROUP + "Stand_Idle");
    }
};

class BruceRunState : PlayerRunState
{
    BruceRunState(Character@ c)
    {
        super(c);
        SetMotion(BRUCE_MOVEMENT_GROUP + "Run_Forward");
    }
};

class BruceTurnState : PlayerTurnState
{
    BruceTurnState(Character@ c)
    {
        super(c);
        AddMotion(BRUCE_MOVEMENT_GROUP + "Turn_Right_90");
        AddMotion(BRUCE_MOVEMENT_GROUP + "Turn_Right_180");
        AddMotion(BRUCE_MOVEMENT_GROUP + "Turn_Left_90");
    }
};

class BruceStandToWalkState : PlayerStandToWalkState
{
    BruceStandToWalkState(Character@ c)
    {
        super(c);
        AddMotion(BRUCE_MOVEMENT_GROUP + "Stand_To_Walk_Right_90");
        AddMotion(BRUCE_MOVEMENT_GROUP + "Stand_To_Walk_Right_180");
        AddMotion(BRUCE_MOVEMENT_GROUP + "Stand_To_Walk_Right_180");
    }
};

class BruceStandToRunState : PlayerStandToRunState
{
    BruceStandToRunState(Character@ c)
    {
        super(c);
        AddMotion(BRUCE_MOVEMENT_GROUP + "Stand_To_Run_Right_180");
    }
};


class BruceWalkState : PlayerWalkState
{
    BruceWalkState(Character@ c)
    {
        super(c);
        SetMotion(BRUCE_MOVEMENT_GROUP + "Walk_Forward");
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
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_02", 14, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_03", 11, ATTACK_KICK, L_FOOT);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_04", 20, ATTACK_KICK, R_FOOT);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_05", 20, ATTACK_PUNCH, R_ARM);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_06", 20, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_07", 16, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_08", 18, ATTACK_PUNCH, R_ARM);

        AddAttackMotion(forwardAttacks, "Attack_Close_Weak_Forward", 11, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Close_Weak_Forward_01", 12, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Close_Weak_Forward_02", 12, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Close_Weak_Forward_03", 11, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Close_Weak_Forward_04", 16, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Close_Weak_Forward_05", 13, ATTACK_PUNCH, L_HAND);

        AddAttackMotion(forwardAttacks, "Attack_Close_Run_Forward", 12, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Far_Forward", 25, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Far_Forward_01", 20, ATTACK_KICK, R_FOOT);
        AddAttackMotion(forwardAttacks, "Attack_Far_Forward_02", 20, ATTACK_KICK, L_FOOT);
        AddAttackMotion(forwardAttacks, "Attack_Far_Forward_03", 22, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Far_Forward_04", 22, ATTACK_KICK, R_FOOT);
        AddAttackMotion(forwardAttacks, "Attack_Run_Far_Forward", 20, ATTACK_KICK, R_FOOT);

        //========================================================================
        // RIGHT
        //========================================================================
        AddAttackMotion(rightAttacks, "Attack_Close_Right", 16, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_01", 18, ATTACK_PUNCH, R_ARM);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_03", 12, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_04", 20, ATTACK_KICK, R_FOOT);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_05", 15, ATTACK_KICK, L_CALF);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_06", 20, ATTACK_KICK, R_FOOT);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_07", 18, ATTACK_PUNCH, R_ARM);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_08", 19, ATTACK_KICK, L_FOOT);

        AddAttackMotion(rightAttacks, "Attack_Close_Weak_Right", 12, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(rightAttacks, "Attack_Close_Weak_Right_01", 10, ATTACK_PUNCH, R_ARM);
        AddAttackMotion(rightAttacks, "Attack_Close_Weak_Right_02", 15, ATTACK_PUNCH, R_HAND);

        AddAttackMotion(rightAttacks, "Attack_Far_Right", 27, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(rightAttacks, "Attack_Far_Right_01", 18, ATTACK_KICK, L_CALF);
        AddAttackMotion(rightAttacks, "Attack_Far_Right_03", 30, ATTACK_KICK, L_FOOT);
        AddAttackMotion(rightAttacks, "Attack_Far_Right_04", 25, ATTACK_KICK, R_FOOT);

        //========================================================================
        // BACK
        //========================================================================
        // back weak
        AddAttackMotion(backAttacks, "Attack_Close_Back", 11, ATTACK_PUNCH, L_ARM);
        AddAttackMotion(backAttacks, "Attack_Close_Back_01", 16, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(backAttacks, "Attack_Close_Back_02", 19, ATTACK_KICK, L_FOOT);
        AddAttackMotion(backAttacks, "Attack_Close_Back_03", 21, ATTACK_KICK, R_FOOT);
        AddAttackMotion(backAttacks, "Attack_Close_Back_04", 18, ATTACK_KICK, R_FOOT);
        AddAttackMotion(backAttacks, "Attack_Close_Back_05", 14, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(backAttacks, "Attack_Close_Back_06", 15, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(backAttacks, "Attack_Close_Back_07", 14, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(backAttacks, "Attack_Close_Back_08", 17, ATTACK_KICK, L_FOOT);

        AddAttackMotion(backAttacks, "Attack_Close_Weak_Back", 12, ATTACK_PUNCH, L_ARM);
        AddAttackMotion(backAttacks, "Attack_Close_Weak_Back_01", 12, ATTACK_PUNCH, R_ARM);

        AddAttackMotion(backAttacks, "Attack_Far_Back", 14, ATTACK_KICK, L_FOOT);
        AddAttackMotion(backAttacks, "Attack_Far_Back_01", 15, ATTACK_KICK, L_FOOT);
        AddAttackMotion(backAttacks, "Attack_Far_Back_02", 20, ATTACK_PUNCH, R_ARM);
        AddAttackMotion(backAttacks, "Attack_Far_Back_04", 33, ATTACK_KICK, L_FOOT);

        //========================================================================
        // LEFT
        //========================================================================
        // left weak
        AddAttackMotion(leftAttacks, "Attack_Close_Left", 7, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_01", 18, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_02", 13, ATTACK_KICK, R_FOOT);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_03", 21, ATTACK_KICK, L_FOOT);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_04", 18, ATTACK_KICK, R_FOOT);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_05", 15, ATTACK_KICK, L_FOOT);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_06", 12, ATTACK_KICK, R_FOOT);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_07", 15, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_08", 16, ATTACK_KICK, L_FOOT);

        AddAttackMotion(leftAttacks, "Attack_Close_Weak_Left", 13, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(leftAttacks, "Attack_Close_Weak_Left_01", 12, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(leftAttacks, "Attack_Close_Weak_Left_02", 13, ATTACK_PUNCH, L_HAND);

        AddAttackMotion(leftAttacks, "Attack_Far_Left", 22, ATTACK_KICK, L_FOOT);
        AddAttackMotion(leftAttacks, "Attack_Far_Left_02", 22, ATTACK_PUNCH, R_ARM);
        AddAttackMotion(leftAttacks, "Attack_Far_Left_03", 21, ATTACK_KICK, L_FOOT);
        AddAttackMotion(leftAttacks, "Attack_Far_Left_04", 30, ATTACK_KICK, L_FOOT);

        PostInit();
    }

    void AddAttackMotion(Array<AttackMotion@>@ attacks, const String&in name, int frame, int type, const String&in bName)
    {
        attacks.Push(AttackMotion("BM_Attack/" + name, frame, type, bName));
    }
};


class BruceCounterState : PlayerCounterState
{
    BruceCounterState(Character@ c)
    {
        super(c);
        @frontArmMotions = bruce_counter_arm_front_motions;
        @backArmMotions = bruce_counter_arm_back_motions;
        @frontLegMotions = bruce_counter_leg_front_motions;
        @backLegMotions = bruce_counter_leg_back_motions;
        @doubleMotions = bruce_counter_double_motions;
        @tripleMotions = bruce_counter_triple_motions;
        @environmentMotions = bruce_counter_environment_motions;

        environmentCounterStartOffsets.Push(Vector4(3.9, 0, 0, -90));
        environmentCounterStartOffsets.Push(Vector4(0, 0, -2.8, 0));
        environmentCounterStartOffsets.Push(Vector4(0, 0, -4.21, 0));
        environmentCounterStartOffsets.Push(Vector4(0, 0, -3.7, 0));
        environmentCounterStartOffsets.Push(Vector4(0, 0, -5.41, 180));
        environmentCounterStartOffsets.Push(Vector4(0, 0, 4.05, 0));
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
        LogPrint("Bruce-Transition Dist=" + BRUCE_TRANSITION_DIST);
    }
};

class BruceRunTurn180State : PlayerRunTurn180State
{
    BruceRunTurn180State(Character@ c)
    {
        super(c);
        AddMotion("BM_Movement/Run_Right_Passing_To_Run_Right_180");
    }
};

class Bruce : Player
{
    Bruce()
    {
        super();
        walkAlignAnimation = GetAnimationName("BM_Movement/Walk_Forward");
    }

    void AddStates()
    {
        stateMachine.AddState(BruceStandState(this));
        stateMachine.AddState(BruceRunState(this));
        stateMachine.AddState(BruceEvadeState(this));
        stateMachine.AddState(CharacterAlignState(this));
        stateMachine.AddState(AnimationTestState(this));

        stateMachine.AddState(BruceAttackState(this));
        stateMachine.AddState(BruceCounterState(this));
        stateMachine.AddState(BruceHitState(this));
        stateMachine.AddState(BruceDeadState(this));
        stateMachine.AddState(BruceBeatDownHitState(this));
        stateMachine.AddState(BruceBeatDownEndState(this));
        stateMachine.AddState(BruceTransitionState(this));

        stateMachine.AddState(BruceWalkState(this));
        stateMachine.AddState(BruceTurnState(this));
        stateMachine.AddState(BruceStandToWalkState(this));
        stateMachine.AddState(BruceStandToRunState(this));
        stateMachine.AddState(BruceRunTurn180State(this));
    }
};

void CreateBruceMotions()
{
    AssignMotionRig("Models/bruce_w.mdl");

    String preFix = BRUCE_MOVEMENT_GROUP;
    Global_AddAnimation(preFix + "Stand_Idle");
    Global_CreateMotion(preFix + "Run_Forward", kMotion_Z, kMotion_Z, -1, true);
    Global_CreateMotion(preFix + "Run_Right_Passing_To_Run_Right_180", kMotion_Turn, kMotion_ZR, 28);

    Global_CreateMotion(preFix + "Turn_Right_90", kMotion_Turn, kMotion_R, 16);
    Global_CreateMotion(preFix + "Turn_Right_180", kMotion_Turn, kMotion_R, 25);
    Global_CreateMotion(preFix + "Turn_Left_90", kMotion_Turn, kMotion_R, 14);
    Global_CreateMotion(preFix + "Walk_Forward", kMotion_Z, kMotion_Z, -1, true);

    Global_CreateMotion(preFix + "Stand_To_Walk_Right_90", kMotion_Turn, kMotion_ZR, 21);
    Global_CreateMotion(preFix + "Stand_To_Walk_Right_180", kMotion_Turn, kMotion_ZR, 25);
    Global_CreateMotion(preFix + "Stand_To_Run_Right_90", kMotion_Turn, kMotion_ZR, 18);
    Global_CreateMotion(preFix + "Stand_To_Run_Right_180", kMotion_Turn, kMotion_ZR, 25);

    preFix = "BM_Combat/";
    Global_CreateMotion(preFix + "Into_Takedown");
    Global_CreateMotion(preFix + "Evade_Forward_01");
    Global_CreateMotion(preFix + "Evade_Back_01");
    Global_CreateMotion(preFix + "Evade_Left_01");
    Global_CreateMotion(preFix + "Evade_Right_01");

    CreateBruceCombatMotions();
}

void CreateBruceCombatMotions()
{
    String preFix = "BM_HitReaction/";
    Global_CreateMotion(preFix + "HitReaction_Back"); // back attacked
    Global_CreateMotion(preFix + "HitReaction_Face_Right"); // front punched
    Global_CreateMotion(preFix + "Hit_Reaction_SideLeft"); // left attacked
    Global_CreateMotion(preFix + "Hit_Reaction_SideRight"); // right attacked

    // Global_CreateMotion_InFolder("BM_Attack/");
    //========================================================================
    // FORWARD
    //========================================================================
    int attackMotionFlags = kMotion_Turn;
    Global_CreateMotion("BM_Attack/Attack_Close_Forward_02", attackMotionFlags).SetDockAlign(L_HAND, 14);
    Global_CreateMotion("BM_Attack/Attack_Close_Forward_03", attackMotionFlags).SetDockAlign(L_FOOT, 11);
    Global_CreateMotion("BM_Attack/Attack_Close_Forward_04", attackMotionFlags).SetDockAlign(R_FOOT, 20);
    Global_CreateMotion("BM_Attack/Attack_Close_Forward_05", attackMotionFlags).SetDockAlign(R_ARM, 20);
    Global_CreateMotion("BM_Attack/Attack_Close_Forward_06", attackMotionFlags).SetDockAlign(R_HAND, 20);
    Global_CreateMotion("BM_Attack/Attack_Close_Forward_07", attackMotionFlags).SetDockAlign(R_HAND, 16);
    Global_CreateMotion("BM_Attack/Attack_Close_Forward_08", attackMotionFlags).SetDockAlign(R_ARM, 18);

    Global_CreateMotion("BM_Attack/Attack_Close_Weak_Forward", attackMotionFlags).SetDockAlign(R_HAND, 11);
    Global_CreateMotion("BM_Attack/Attack_Close_Weak_Forward_01", attackMotionFlags).SetDockAlign(L_HAND, 12);
    Global_CreateMotion("BM_Attack/Attack_Close_Weak_Forward_02", attackMotionFlags).SetDockAlign(L_HAND, 12);
    Global_CreateMotion("BM_Attack/Attack_Close_Weak_Forward_03", attackMotionFlags).SetDockAlign(L_HAND, 12);
    Global_CreateMotion("BM_Attack/Attack_Close_Weak_Forward_04", attackMotionFlags).SetDockAlign(R_HAND, 16);
    Global_CreateMotion("BM_Attack/Attack_Close_Weak_Forward_05", attackMotionFlags).SetDockAlign(L_HAND, 13);

    Global_CreateMotion("BM_Attack/Attack_Close_Run_Forward", attackMotionFlags).SetDockAlign(R_HAND, 12);
    Global_CreateMotion("BM_Attack/Attack_Far_Forward", attackMotionFlags).SetDockAlign(R_HAND, 25);
    Global_CreateMotion("BM_Attack/Attack_Far_Forward_01", attackMotionFlags).SetDockAlign(R_FOOT, 20);
    Global_CreateMotion("BM_Attack/Attack_Far_Forward_02", attackMotionFlags).SetDockAlign(L_FOOT, 20);
    Global_CreateMotion("BM_Attack/Attack_Far_Forward_03", attackMotionFlags).SetDockAlign(R_HAND, 22);
    Global_CreateMotion("BM_Attack/Attack_Far_Forward_04", attackMotionFlags).SetDockAlign(R_FOOT, 22);
    Global_CreateMotion("BM_Attack/Attack_Run_Far_Forward", attackMotionFlags).SetDockAlign(R_FOOT, 20);

    //========================================================================
    // RIGHT
    //========================================================================
    Global_CreateMotion("BM_Attack/Attack_Close_Right", attackMotionFlags).SetDockAlign(L_HAND, 16);
    Global_CreateMotion("BM_Attack/Attack_Close_Right_01", attackMotionFlags).SetDockAlign(R_ARM, 18);
    Global_CreateMotion("BM_Attack/Attack_Close_Right_03", attackMotionFlags).SetDockAlign(L_HAND, 12);
    Global_CreateMotion("BM_Attack/Attack_Close_Right_04", attackMotionFlags).SetDockAlign(R_FOOT, 20);
    Global_CreateMotion("BM_Attack/Attack_Close_Right_05", attackMotionFlags).SetDockAlign(L_CALF, 15);
    Global_CreateMotion("BM_Attack/Attack_Close_Right_06", attackMotionFlags).SetDockAlign(R_FOOT, 20);
    Global_CreateMotion("BM_Attack/Attack_Close_Right_07", attackMotionFlags).SetDockAlign(R_ARM, 18);
    Global_CreateMotion("BM_Attack/Attack_Close_Right_08", attackMotionFlags).SetDockAlign(L_FOOT, 19);

    Global_CreateMotion("BM_Attack/Attack_Close_Weak_Right", attackMotionFlags).SetDockAlign(L_HAND, 12);
    Global_CreateMotion("BM_Attack/Attack_Close_Weak_Right_01", attackMotionFlags).SetDockAlign(R_ARM, 10);
    Global_CreateMotion("BM_Attack/Attack_Close_Weak_Right_02", attackMotionFlags).SetDockAlign(R_HAND, 15);

    Global_CreateMotion("BM_Attack/Attack_Far_Right", attackMotionFlags).SetDockAlign(L_HAND, 27);
    Global_CreateMotion("BM_Attack/Attack_Far_Right_01", attackMotionFlags).SetDockAlign(L_CALF, 18);
    Global_CreateMotion("BM_Attack/Attack_Far_Right_03", attackMotionFlags).SetDockAlign(L_FOOT, 30);;
    Global_CreateMotion("BM_Attack/Attack_Far_Right_04", attackMotionFlags).SetDockAlign(R_FOOT, 25);


    //========================================================================
    // BACK
    //========================================================================
    Global_CreateMotion("BM_Attack/Attack_Close_Back", attackMotionFlags).SetDockAlign(L_ARM, 11);
    Global_CreateMotion("BM_Attack/Attack_Close_Back_01", attackMotionFlags).SetDockAlign(L_HAND, 16);
    Global_CreateMotion("BM_Attack/Attack_Close_Back_02", attackMotionFlags).SetDockAlign(L_FOOT, 19);
    Global_CreateMotion("BM_Attack/Attack_Close_Back_03", attackMotionFlags).SetDockAlign(R_FOOT, 21);
    Global_CreateMotion("BM_Attack/Attack_Close_Back_04", attackMotionFlags).SetDockAlign(R_FOOT, 18);
    Global_CreateMotion("BM_Attack/Attack_Close_Back_05", attackMotionFlags).SetDockAlign(L_HAND, 14);
    Global_CreateMotion("BM_Attack/Attack_Close_Back_06", attackMotionFlags).SetDockAlign(R_HAND, 15);
    Global_CreateMotion("BM_Attack/Attack_Close_Back_07", attackMotionFlags).SetDockAlign(L_HAND, 14);
    Global_CreateMotion("BM_Attack/Attack_Close_Back_08", attackMotionFlags).SetDockAlign(L_FOOT, 17);

    Global_CreateMotion("BM_Attack/Attack_Close_Weak_Back", attackMotionFlags).SetDockAlign(L_ARM, 12);
    Global_CreateMotion("BM_Attack/Attack_Close_Weak_Back_01", attackMotionFlags).SetDockAlign(R_ARM, 12);

    Global_CreateMotion("BM_Attack/Attack_Far_Back", attackMotionFlags).SetDockAlign(L_FOOT, 14);
    Global_CreateMotion("BM_Attack/Attack_Far_Back_01", attackMotionFlags).SetDockAlign(L_FOOT, 15);
    Global_CreateMotion("BM_Attack/Attack_Far_Back_02", attackMotionFlags).SetDockAlign(R_ARM, 20);
    Global_CreateMotion("BM_Attack/Attack_Far_Back_04", attackMotionFlags).SetDockAlign(L_FOOT, 33);

    //========================================================================
    // LEFT
    //========================================================================
    Global_CreateMotion("BM_Attack/Attack_Close_Left", attackMotionFlags).SetDockAlign(R_HAND, 7);
    Global_CreateMotion("BM_Attack/Attack_Close_Left_01", attackMotionFlags).SetDockAlign(R_HAND, 18);
    Global_CreateMotion("BM_Attack/Attack_Close_Left_02", attackMotionFlags).SetDockAlign(R_FOOT, 13);
    Global_CreateMotion("BM_Attack/Attack_Close_Left_03", attackMotionFlags).SetDockAlign(L_FOOT, 21);
    Global_CreateMotion("BM_Attack/Attack_Close_Left_04", attackMotionFlags).SetDockAlign(R_FOOT, 18);
    Global_CreateMotion("BM_Attack/Attack_Close_Left_05", attackMotionFlags).SetDockAlign(L_FOOT, 15);
    Global_CreateMotion("BM_Attack/Attack_Close_Left_06", attackMotionFlags).SetDockAlign(R_FOOT, 12);
    Global_CreateMotion("BM_Attack/Attack_Close_Left_07", attackMotionFlags).SetDockAlign(L_HAND, 15);
    Global_CreateMotion("BM_Attack/Attack_Close_Left_08", attackMotionFlags).SetDockAlign(L_FOOT, 16);

    Global_CreateMotion("BM_Attack/Attack_Close_Weak_Left", attackMotionFlags).SetDockAlign(R_HAND, 13);
    Global_CreateMotion("BM_Attack/Attack_Close_Weak_Left_01", attackMotionFlags).SetDockAlign(R_HAND, 12);
    Global_CreateMotion("BM_Attack/Attack_Close_Weak_Left_02", attackMotionFlags).SetDockAlign(L_HAND, 13);

    Global_CreateMotion("BM_Attack/Attack_Far_Left", attackMotionFlags).SetDockAlign(L_FOOT, 22);
    Global_CreateMotion("BM_Attack/Attack_Far_Left_02", attackMotionFlags).SetDockAlign(R_ARM, 22);
    Global_CreateMotion("BM_Attack/Attack_Far_Left_03", attackMotionFlags).SetDockAlign(L_FOOT, 21);
    Global_CreateMotion("BM_Attack/Attack_Far_Left_04", attackMotionFlags).SetDockAlign(L_FOOT, 30);


    Global_CreateMotion("BM_Attack/Beatdown_Strike_Start_01");
    Global_CreateMotion("BM_Attack/Beatdown_Test_01");
    Global_CreateMotion("BM_Attack/Beatdown_Test_02");
    Global_CreateMotion("BM_Attack/Beatdown_Test_03");
    Global_CreateMotion("BM_Attack/Beatdown_Test_04");
    Global_CreateMotion("BM_Attack/Beatdown_Test_05");
    Global_CreateMotion("BM_Attack/Beatdown_Test_06");

    /*
    Global_CreateMotion("BM_Attack/Attack_Far_Back_03");
    Global_CreateMotion("BM_Attack/Attack_Far_Left_01");
    Global_CreateMotion("BM_Attack/Attack_Far_Right_02");
    Global_CreateMotion("BM_Attack/Attack_StunPush");
    Global_CreateMotion("BM_Attack/Block_Left");
    Global_CreateMotion("BM_Attack/Block_Right");
    Global_CreateMotion("BM_Attack/CapeDistract_Close_Forward");
    Global_CreateMotion("BM_Attack/CapeDistract_Far_Forward");
    Global_CreateMotion("BM_Attack/Redirect_push_back");
    Global_CreateMotion("BM_Attack/Super_Stun_01");
    Global_CreateMotion("BM_Attack/Super_Stun_02");
    */

    // arm front
    bruce_counter_arm_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Front_01"));
    bruce_counter_arm_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Front_02"));
    bruce_counter_arm_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Front_03"));
    bruce_counter_arm_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Front_04"));
    bruce_counter_arm_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Front_05"));
    bruce_counter_arm_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Front_06"));
    bruce_counter_arm_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Front_07"));
    bruce_counter_arm_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Front_08"));
    bruce_counter_arm_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Front_09"));
    bruce_counter_arm_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Front_10"));
    bruce_counter_arm_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Front_13"));
    bruce_counter_arm_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Front_14"));
    bruce_counter_arm_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Front_Weak_02"));
    bruce_counter_arm_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Front_Weak_03"));
    bruce_counter_arm_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Front_Weak_04"));

    // leg front
    bruce_counter_leg_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Front_01"));
    bruce_counter_leg_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Front_02"));
    bruce_counter_leg_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Front_03"));
    bruce_counter_leg_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Front_04"));
    bruce_counter_leg_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Front_05"));
    bruce_counter_leg_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Front_06"));
    bruce_counter_leg_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Front_07"));
    bruce_counter_leg_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Front_08"));
    bruce_counter_leg_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Front_09"));
    bruce_counter_leg_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Front_Weak_01"));
    bruce_counter_leg_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Front_Weak_02"));
    bruce_counter_leg_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Front_Weak"));

    // arm back
    bruce_counter_arm_back_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Back_01"));
    bruce_counter_arm_back_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Back_02"));
    bruce_counter_arm_back_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Back_03"));
    bruce_counter_arm_back_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Back_05"));
    bruce_counter_arm_back_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Back_06"));
    bruce_counter_arm_back_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Back_Weak_01"));
    bruce_counter_arm_back_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Back_Weak_02"));
    bruce_counter_arm_back_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Back_Weak_03"));

    // leg back
    bruce_counter_leg_back_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Back_01"));
    bruce_counter_leg_back_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Back_02"));
    bruce_counter_leg_back_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Back_03"));
    bruce_counter_leg_back_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Back_04"));
    bruce_counter_leg_back_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Back_05"));
    bruce_counter_leg_back_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Back_Weak_01"));
    bruce_counter_leg_back_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Back_Weak_03"));

    // double counter
    preFix = "BM_TG_Counter/";
    bruce_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsA"));
    bruce_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsB"));
    bruce_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsD"));
    bruce_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsE"));
    bruce_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsF"));
    bruce_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsG"));
    bruce_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsH"));

    // tripple counter
    bruce_counter_triple_motions.Push(Global_CreateMotion(preFix + "Double_Counter_3ThugsA"));
    bruce_counter_triple_motions.Push(Global_CreateMotion(preFix + "Double_Counter_3ThugsB"));
    bruce_counter_triple_motions.Push(Global_CreateMotion(preFix + "Double_Counter_3ThugsC"));

    // environment counter
    /*bruce_counter_environment_motions.Push(Global_CreateMotion(preFix + "Environment_Counter_128_Back_02"));
    bruce_counter_environment_motions.Push(Global_CreateMotion(preFix + "Environment_Counter_128_Front_01"));
    bruce_counter_environment_motions.Push(Global_CreateMotion(preFix + "Environment_Counter_128_Left_01"));
    bruce_counter_environment_motions.Push(Global_CreateMotion(preFix + "Environment_Counter_128_Right_01"));
    bruce_counter_environment_motions.Push(Global_CreateMotion(preFix + "Environment_Counter_128_Right_02"));*/
    bruce_counter_environment_motions.Push(Global_CreateMotion(preFix + "Environment_Counter_Wall_Back_02")); // wall (3.9,0,0) -90
    bruce_counter_environment_motions.Push(Global_CreateMotion(preFix + "Environment_Counter_Wall_Front_01")); // wall (0,0,-3) 0
    bruce_counter_environment_motions.Push(Global_CreateMotion(preFix + "Environment_Counter_Wall_Front_02")); // wall (0,0,-4.21) 0
    bruce_counter_environment_motions.Push(Global_CreateMotion(preFix + "Environment_Counter_Wall_Left_02")); // wall(0,0,-3.7) 0
    bruce_counter_environment_motions.Push(Global_CreateMotion(preFix + "Environment_Counter_Wall_Right")); // wall (0,0,-5.41) 180
    bruce_counter_environment_motions.Push(Global_CreateMotion(preFix + "Environment_Counter_Wall_Right_02")); // wall (0,0,4.05) 0

    preFix = "BM_Death_Primers/";
    Global_CreateMotion(preFix + "Death_Front");
    Global_CreateMotion(preFix + "Death_Back");
    Global_CreateMotion(preFix + "Death_Side_Left");
    Global_CreateMotion(preFix + "Death_Side_Right");

    //preFix = "BM_Attack/";
    //for (uint i=1; i<=6; ++i)
    //    Global_CreateMotion(preFix + "Beatdown_Test_0" + i);

    preFix = "BM_TG_Beatdown/";
    for (uint i=1; i<=4; ++i)
        Global_CreateMotion(preFix + "Beatdown_Strike_End_0" + i);
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

    preFix = "BM_TG_Counter/";
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

    animName = preFix + "Counter_Arm_Back_05";
    AddStringAnimationTrigger(animName, 30, COMBAT_SOUND, R_ARM);
    AddAnimationTrigger(animName, 60, READY_TO_FIGHT);

    animName = preFix + "Counter_Arm_Back_06";
    AddStringAnimationTrigger(animName, 50, COMBAT_SOUND, R_HAND);
    AddAnimationTrigger(animName, 70, READY_TO_FIGHT);

    animName = preFix + "Counter_Arm_Back_Weak_01";
    AddStringAnimationTrigger(animName, 11, COMBAT_SOUND, R_ARM);
    AddStringAnimationTrigger(animName, 25, COMBAT_SOUND, R_ARM);
    AddAnimationTrigger(animName, 27, READY_TO_FIGHT);

    animName = preFix + "Counter_Arm_Back_Weak_02";
    AddStringAnimationTrigger(animName, 4, COMBAT_SOUND, R_ARM);
    AddStringAnimationTrigger(animName, 15, COMBAT_SOUND, L_HAND);
    AddAnimationTrigger(animName, 45, READY_TO_FIGHT);

    animName = preFix + "Counter_Arm_Back_Weak_03";
    AddStringAnimationTrigger(animName, 27, COMBAT_SOUND, R_HAND);
    AddAnimationTrigger(animName, 46, READY_TO_FIGHT);

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

    animName = preFix + "Counter_Arm_Front_13";
    AddStringAnimationTrigger(animName, 17, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 40, COMBAT_SOUND, L_FOOT);
    AddAnimationTrigger(animName, 60, READY_TO_FIGHT);

    animName = preFix + "Counter_Arm_Front_14";
    AddStringAnimationTrigger(animName, 5, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 22, COMBAT_SOUND, R_HAND);
    AddStringAnimationTrigger(animName, 50, COMBAT_SOUND, R_FOOT);
    AddAnimationTrigger(animName, 72, READY_TO_FIGHT);

    animName = preFix + "Counter_Arm_Front_Weak_02";
    AddStringAnimationTrigger(animName, 4, COMBAT_SOUND, L_ARM);
    AddStringAnimationTrigger(animName, 9, COMBAT_SOUND, R_HAND);
    AddStringAnimationTrigger(animName, 21, COMBAT_SOUND, L_HAND);
    AddAnimationTrigger(animName, 23, READY_TO_FIGHT);

    animName = preFix + "Counter_Arm_Front_Weak_03";
    AddStringAnimationTrigger(animName, 6, COMBAT_SOUND, L_ARM);
    AddStringAnimationTrigger(animName, 26, COMBAT_SOUND, R_HAND);
    AddAnimationTrigger(animName, 55, READY_TO_FIGHT);

    animName = preFix + "Counter_Arm_Front_Weak_04";
    AddStringAnimationTrigger(animName, 14, COMBAT_SOUND, R_ARM);
    AddAnimationTrigger(animName, 57, READY_TO_FIGHT);

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

    animName = preFix + "Counter_Leg_Back_03";
    AddStringAnimationTrigger(animName, 7, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 15, COMBAT_SOUND, R_ARM);
    AddStringAnimationTrigger(animName, 46, COMBAT_SOUND, L_CALF);
    AddAnimationTrigger(animName, 48, READY_TO_FIGHT);

    animName = preFix + "Counter_Leg_Back_04";
    AddStringAnimationTrigger(animName, 30, COMBAT_SOUND, L_FOOT);
    AddAnimationTrigger(animName, 48, READY_TO_FIGHT);

    animName = preFix + "Counter_Leg_Back_Weak_01";
    AddStringAnimationTrigger(animName, 7, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 30, COMBAT_SOUND, R_ARM);
    AddAnimationTrigger(animName, 32, READY_TO_FIGHT);

    animName = preFix + "Counter_Leg_Back_Weak_03";
    AddStringAnimationTrigger(animName, 12, COMBAT_SOUND, R_ARM);
    AddStringAnimationTrigger(animName, 18, COMBAT_SOUND, R_ARM);
    AddAnimationTrigger(animName, 64, READY_TO_FIGHT);

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

    animName = preFix + "Counter_Leg_Front_07";
    AddStringAnimationTrigger(animName, 12, COMBAT_SOUND, R_HAND);
    AddStringAnimationTrigger(animName, 42, COMBAT_SOUND, R_FOOT);
    AddAnimationTrigger(animName, 68, READY_TO_FIGHT);

    animName = preFix + "Counter_Leg_Front_08";
    AddStringAnimationTrigger(animName, 5, COMBAT_SOUND, R_ARM);
    AddStringAnimationTrigger(animName, 20, COMBAT_SOUND, L_ARM);
    AddAnimationTrigger(animName, 40, READY_TO_FIGHT);

    animName = preFix + "Counter_Leg_Front_Weak";
    AddStringAnimationTrigger(animName, 12, COMBAT_SOUND, L_FOOT);
    AddStringAnimationTrigger(animName, 18, COMBAT_SOUND, L_FOOT);
    AddAnimationTrigger(animName, 20, READY_TO_FIGHT);

    animName = preFix + "Counter_Leg_Front_Weak_01";
    AddStringAnimationTrigger(animName, 10, COMBAT_SOUND, R_HAND);
    AddStringAnimationTrigger(animName, 25, COMBAT_SOUND, R_HAND);
    AddAnimationTrigger(animName, 65, READY_TO_FIGHT);

    animName = preFix + "Counter_Leg_Front_Weak_02";
    AddStringAnimationTrigger(animName, 9, COMBAT_SOUND, L_FOOT);
    AddStringAnimationTrigger(animName, 19, COMBAT_SOUND, L_ARM);
    AddAnimationTrigger(animName, 52, READY_TO_FIGHT);

    animName = preFix + "Double_Counter_2ThugsA";
    AddStringAnimationTrigger(animName, 12, PARTICLE, R_HAND);
    AddStringAnimationTrigger(animName, 12, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 77, PARTICLE, R_HAND);
    AddStringAnimationTrigger(animName, 77, COMBAT_SOUND_LARGE, R_HAND);
    AddAnimationTrigger(animName, 79, READY_TO_FIGHT);

    animName = preFix + "Double_Counter_2ThugsB";
    AddStringAnimationTrigger(animName, 12, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 36, COMBAT_SOUND_LARGE, L_HAND);
    AddAnimationTrigger(animName, 60, READY_TO_FIGHT);

    animName = preFix + "Double_Counter_2ThugsD";
    AddStringAnimationTrigger(animName, 7, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 7, PARTICLE, R_HAND);
    AddStringAnimationTrigger(animName, 15, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 38, PARTICLE, L_HAND);
    AddStringAnimationTrigger(animName, 38, COMBAT_SOUND_LARGE, R_HAND);
    AddAnimationTrigger(animName, 43, READY_TO_FIGHT);

    animName = preFix + "Double_Counter_2ThugsE";
    AddStringAnimationTrigger(animName, 21, COMBAT_SOUND, R_ARM);
    AddStringAnimationTrigger(animName, 43, COMBAT_SOUND, L_FOOT);
    AddStringAnimationTrigger(animName, 76, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 83, COMBAT_SOUND_LARGE, L_HAND);
    AddAnimationTrigger(animName, 85, READY_TO_FIGHT);

    animName = preFix + "Double_Counter_2ThugsF";
    AddStringAnimationTrigger(animName, 26, COMBAT_SOUND_LARGE, L_FOOT);
    AddStringAnimationTrigger(animName, 26, PARTICLE, R_FOOT);
    AddAnimationTrigger(animName, 60, READY_TO_FIGHT);

    animName = preFix + "Double_Counter_2ThugsG";
    AddStringAnimationTrigger(animName, 23, COMBAT_SOUND_LARGE, L_HAND);
    AddStringAnimationTrigger(animName, 23, PARTICLE, R_HAND);
    AddAnimationTrigger(animName, 25, READY_TO_FIGHT);

    animName = preFix + "Double_Counter_2ThugsH";
    AddStringAnimationTrigger(animName, 21, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 21, PARTICLE, R_HAND);
    AddStringAnimationTrigger(animName, 36, PARTICLE, L_HAND);
    AddStringAnimationTrigger(animName, 36, COMBAT_SOUND_LARGE, R_HAND);
    AddAnimationTrigger(animName, 65, READY_TO_FIGHT);

    animName = preFix + "Double_Counter_3ThugsA";
    AddStringAnimationTrigger(animName, 7, PARTICLE, L_HAND);
    AddStringAnimationTrigger(animName, 7, PARTICLE, R_ARM);
    AddStringAnimationTrigger(animName, 27, COMBAT_SOUND_LARGE, R_HAND);
    AddAnimationTrigger(animName, 50, READY_TO_FIGHT);

    animName = preFix + "Double_Counter_3ThugsB";
    AddStringAnimationTrigger(animName, 27, PARTICLE, L_FOOT);
    AddStringAnimationTrigger(animName, 27, PARTICLE, R_FOOT);
    AddStringAnimationTrigger(animName, 27, COMBAT_SOUND_LARGE, R_HAND);
    AddAnimationTrigger(animName, 50, READY_TO_FIGHT);

    animName = preFix + "Double_Counter_3ThugsC";
    AddStringAnimationTrigger(animName, 5, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 5, PARTICLE, R_HAND);
    AddStringAnimationTrigger(animName, 37, PARTICLE, L_FOOT);
    AddStringAnimationTrigger(animName, 37, COMBAT_SOUND_LARGE, R_HAND);
    AddAnimationTrigger(animName, 52, READY_TO_FIGHT);

    animName = preFix + "Environment_Counter_Wall_Back_02";
    AddStringAnimationTrigger(animName, 7, COMBAT_SOUND, R_HAND);
    AddStringAnimationTrigger(animName, 7, PARTICLE, R_HAND);
    AddStringAnimationTrigger(animName, 44, COMBAT_SOUND, R_ARM);
    AddStringAnimationTrigger(animName, 57, COMBAT_SOUND, R_ARM);
    AddStringAnimationTrigger(animName, 57, COMBAT_SOUND_LARGE, R_ARM);
    AddAnimationTrigger(animName, 86, READY_TO_FIGHT);

    animName = preFix + "Environment_Counter_Wall_Front_01";
    AddStringAnimationTrigger(animName, 8, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 8, PARTICLE, L_HAND);
    AddStringAnimationTrigger(animName, 25, PARTICLE, L_HAND);
    AddStringAnimationTrigger(animName, 25, COMBAT_SOUND_LARGE, L_HAND);
    AddAnimationTrigger(animName, 55, READY_TO_FIGHT);

    animName = preFix + "Environment_Counter_Wall_Front_02";
    AddStringAnimationTrigger(animName, 7, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 7, PARTICLE, L_HAND);
    AddStringAnimationTrigger(animName, 30, COMBAT_SOUND_LARGE, L_HAND);
    AddAnimationTrigger(animName, 70, READY_TO_FIGHT);

    animName = preFix + "Environment_Counter_Wall_Left_02";
    AddStringAnimationTrigger(animName, 25, COMBAT_SOUND_LARGE, R_HAND);
    AddStringAnimationTrigger(animName, 25, PARTICLE, R_HAND);
    AddAnimationTrigger(animName, 66, READY_TO_FIGHT);

    animName = preFix + "Environment_Counter_Wall_Right";
    AddStringAnimationTrigger(animName, 46, COMBAT_SOUND_LARGE, R_HAND);
    AddStringAnimationTrigger(animName, 46, PARTICLE, R_HAND);
    AddAnimationTrigger(animName, 62, READY_TO_FIGHT);

    animName = preFix + "Environment_Counter_Wall_Right_02";
    AddStringAnimationTrigger(animName, 7, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 7, PARTICLE, L_HAND);
    AddStringAnimationTrigger(animName, 39, COMBAT_SOUND_LARGE, L_HAND);
    AddStringAnimationTrigger(animName, 39, PARTICLE, L_HAND);
    AddAnimationTrigger(animName, 52, READY_TO_FIGHT);
}

void AddBruceAnimationTriggers()
{
    String preFix = "BM_Combat/";
    AddAnimationTrigger(preFix + "Evade_Forward_01", 48, READY_TO_FIGHT);
    AddAnimationTrigger(preFix + "Evade_Back_01", 48, READY_TO_FIGHT);
    AddAnimationTrigger(preFix + "Evade_Left_01", 48, READY_TO_FIGHT);
    AddAnimationTrigger(preFix + "Evade_Right_01", 48, READY_TO_FIGHT);

    preFix = BRUCE_MOVEMENT_GROUP;
    AddStringAnimationTrigger(preFix + "Walk_Forward", 11, FOOT_STEP, R_FOOT);
    AddStringAnimationTrigger(preFix + "Walk_Forward", 24, FOOT_STEP, L_FOOT);
    AddStringAnimationTrigger(preFix + "Turn_Right_90", 11, FOOT_STEP, R_FOOT);
    AddStringAnimationTrigger(preFix + "Turn_Right_90", 15, FOOT_STEP, L_FOOT);
    AddStringAnimationTrigger(preFix + "Turn_Right_180", 13, FOOT_STEP, R_FOOT);
    AddStringAnimationTrigger(preFix + "Turn_Right_180", 20, FOOT_STEP, L_FOOT);
    AddStringAnimationTrigger(preFix + "Turn_Left_90", 13, FOOT_STEP, L_FOOT);
    AddStringAnimationTrigger(preFix + "Turn_Left_90", 20, FOOT_STEP, R_FOOT);

    AddBruceCombatAnimationTriggers();
}


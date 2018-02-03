// ==============================================
//
//    Bruce Class
//
// ==============================================

class BruceStandState : PlayerStandState
{
    BruceStandState(Character@ c)
    {
        super(c);
        AddMotion(BRUCE_MOVEMENT_GROUP + "Stand_Idle");
        AddMotion(BRUCE_MOVEMENT_GROUP + "Stand_Idle_01");
        AddMotion(BRUCE_MOVEMENT_GROUP + "Stand_Idle_02");
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
        AddMotion(BRUCE_MOVEMENT_GROUP + "Turn_Right_90");
        AddMotion(BRUCE_MOVEMENT_GROUP + "Turn_Right_180");
        AddMotion(BRUCE_MOVEMENT_GROUP + "Turn_Left_90");
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

class BruceAttackState : PlayerAttackState
{
    BruceAttackState(Character@ c)
    {
        super(c);

        BM_Game_MotionManager@ mgr = cast<BM_Game_MotionManager>(gMotionMgr);
        @forwardAttacks = mgr.bruce_forward_attack_motions;
        @rightAttacks = mgr.bruce_right_attack_motions;
        @backAttacks = mgr.bruce_back_attack_motions;
        @leftAttacks = mgr.bruce_left_attack_motions;

        PostInit();
    }
};


class BruceCounterState : PlayerCounterState
{
    BruceCounterState(Character@ c)
    {
        super(c);

        BM_Game_MotionManager@ mgr = cast<BM_Game_MotionManager>(gMotionMgr);
        @frontArmMotions = mgr.bruce_counter_arm_front_motions;
        @backArmMotions = mgr.bruce_counter_arm_back_motions;
        @frontLegMotions = mgr.bruce_counter_leg_front_motions;
        @backLegMotions = mgr.bruce_counter_leg_back_motions;
        @doubleMotions = mgr.bruce_counter_double_motions;
        @tripleMotions = mgr.bruce_counter_triple_motions;
        @environmentMotions = mgr.bruce_counter_environment_motions;

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

class BruceTransitionState : PlayerTransitionState
{
    BruceTransitionState(Character@ c)
    {
        super(c);
        SetMotion("BM_Combat/Into_Takedown");
        LogPrint("Bruce-Transition Dist=" + motion.endDistance);
    }
};

class Bruce : Player
{
    Bruce()
    {
        super();
    }

    void AddStates()
    {
        stateMachine.AddState(BruceStandState(this));
        stateMachine.AddState(BruceRunState(this));
        stateMachine.AddState(AnimationTestState(this));

        stateMachine.AddState(BruceAttackState(this));
        stateMachine.AddState(BruceCounterState(this));
        stateMachine.AddState(BruceHitState(this));
        stateMachine.AddState(BruceDeadState(this));
        stateMachine.AddState(BruceTransitionState(this));

        stateMachine.AddState(BruceWalkState(this));
        stateMachine.AddState(BruceTurnState(this));
        stateMachine.AddState(BruceStandToWalkState(this));
        stateMachine.AddState(BruceStandToRunState(this));
    }
};

void CreateBruceMotions()
{
    AssignMotionRig("Models/elm2.mdl");

    String preFix = BRUCE_MOVEMENT_GROUP;
    Global_AddAnimation(preFix + "Stand_Idle");
    Global_AddAnimation(preFix + "Stand_Idle_01");
    Global_AddAnimation(preFix + "Stand_Idle_02");
    Global_CreateMotion(preFix + "Run_Forward", kMotion_Z, kMotion_Z, -1, true);

    int locomotionFlags = kMotion_XZR;
    Global_CreateMotion(preFix + "Turn_Right_90", locomotionFlags, kMotion_R, 16);
    Global_CreateMotion(preFix + "Turn_Right_180", locomotionFlags, kMotion_R, 25);
    Global_CreateMotion(preFix + "Turn_Left_90", locomotionFlags, kMotion_R, 14);
    Global_CreateMotion(preFix + "Walk_Forward", kMotion_Z, kMotion_Z, -1, true);

    Global_CreateMotion(preFix + "Stand_To_Walk_Right_90", locomotionFlags, kMotion_ZR, 21);
    Global_CreateMotion(preFix + "Stand_To_Walk_Right_180", locomotionFlags, kMotion_ZR, 25);
    Global_CreateMotion(preFix + "Stand_To_Run_Right_90", locomotionFlags, kMotion_ZR, 18);
    Global_CreateMotion(preFix + "Stand_To_Run_Right_180", locomotionFlags, kMotion_ZR, 25);

    preFix = "BM_Combat/";
    Global_CreateMotion(preFix + "Into_Takedown");

    CreateBruceCombatMotions();
}

void CreateBruceCombatMotions()
{
    BM_Game_MotionManager@ mgr = cast<BM_Game_MotionManager>(gMotionMgr);

    String preFix = "BM_HitReaction/";
    Global_CreateMotion(preFix + "HitReaction_Back"); // back attacked
    Global_CreateMotion(preFix + "HitReaction_Face_Right"); // front punched
    Global_CreateMotion(preFix + "Hit_Reaction_SideLeft"); // left attacked
    Global_CreateMotion(preFix + "Hit_Reaction_SideRight"); // right attacked


    int flags = kMotion_XZR | kMotion_Ext_DoNotRotateAnimation;
    //========================================================================
    // FORWARD
    //========================================================================
    mgr.bruce_forward_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Forward_02", flags, L_HAND, 14));
    mgr.bruce_forward_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Forward_03", flags, L_FOOT, 12));
    mgr.bruce_forward_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Forward_04", flags, R_FOOT, 20));
    mgr.bruce_forward_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Forward_05", flags, R_ARM, 20));
    mgr.bruce_forward_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Forward_06", flags, R_HAND, 20));
    mgr.bruce_forward_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Forward_07", flags, R_HAND, 16));
    mgr.bruce_forward_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Forward_08", flags, R_ARM, 18));

    mgr.bruce_forward_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Weak_Forward", flags, R_HAND, 11));
    mgr.bruce_forward_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Weak_Forward_01", flags, L_HAND, 12));
    mgr.bruce_forward_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Weak_Forward_02", flags, L_HAND, 12));
    mgr.bruce_forward_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Weak_Forward_03", flags, L_HAND, 12));
    mgr.bruce_forward_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Weak_Forward_04", flags, R_HAND, 16));
    mgr.bruce_forward_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Weak_Forward_05", flags, L_HAND, 13));

    mgr.bruce_forward_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Run_Forward", flags, R_HAND, 12));
    mgr.bruce_forward_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Far_Forward", flags, R_ARM, 25));
    mgr.bruce_forward_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Far_Forward_01", flags, R_FOOT, 20));
    mgr.bruce_forward_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Far_Forward_02", flags, L_FOOT, 20));
    mgr.bruce_forward_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Far_Forward_03", flags, R_HAND, 22));
    mgr.bruce_forward_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Far_Forward_04", flags, R_FOOT, 22));
    mgr.bruce_forward_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Run_Far_Forward", flags, R_FOOT, 20));


    //========================================================================
    // RIGHT
    //========================================================================
    mgr.bruce_right_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Right", flags, L_HAND, 16));
    mgr.bruce_right_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Right_01", flags, R_HAND, 18));
    mgr.bruce_right_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Right_03", flags, L_HAND, 12));
    mgr.bruce_right_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Right_04", flags, R_FOOT, 20));
    mgr.bruce_right_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Right_05", flags, L_CALF, 15));
    mgr.bruce_right_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Right_06", flags, R_FOOT, 20));
    mgr.bruce_right_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Right_07", flags, R_ARM, 18));
    mgr.bruce_right_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Right_08", flags, L_FOOT, 19));

    mgr.bruce_right_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Weak_Right", flags, L_HAND, 12));
    mgr.bruce_right_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Weak_Right_01", flags, R_ARM, 10));
    mgr.bruce_right_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Weak_Right_02", flags, R_HAND, 15));

    mgr.bruce_right_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Far_Right", flags, L_HAND, 27));
    mgr.bruce_right_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Far_Right_01", flags, L_CALF, 18));
    mgr.bruce_right_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Far_Right_03", flags, L_FOOT, 30));
    mgr.bruce_right_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Far_Right_04", flags, R_FOOT, 25));


    //========================================================================
    // BACK
    //========================================================================
    mgr.bruce_back_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Back", flags, L_ARM, 11));
    mgr.bruce_back_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Back_01", flags, L_HAND, 16));
    mgr.bruce_back_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Back_02", flags, L_FOOT, 19));
    mgr.bruce_back_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Back_03", flags, R_FOOT, 21));
    mgr.bruce_back_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Back_04", flags, R_FOOT, 18));
    mgr.bruce_back_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Back_05", flags, L_HAND, 14));
    mgr.bruce_back_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Back_06", flags, R_HAND, 15));
    mgr.bruce_back_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Back_07", flags, L_HAND, 14));
    mgr.bruce_back_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Back_08", flags, L_FOOT, 17));

    mgr.bruce_back_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Weak_Back", flags, L_ARM, 12));
    mgr.bruce_back_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Weak_Back_01", flags, R_HAND, 14));

    mgr.bruce_back_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Far_Back", flags, L_FOOT, 14));
    mgr.bruce_back_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Far_Back_01", flags, L_FOOT, 18));
    mgr.bruce_back_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Far_Back_02", flags, R_ARM, 20));
    mgr.bruce_back_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Far_Back_04", flags, L_FOOT, 33));

    //========================================================================
    // LEFT
    //========================================================================
    mgr.bruce_left_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Left", flags, R_HAND, 7));
    mgr.bruce_left_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Left_01", flags, R_HAND, 18));
    mgr.bruce_left_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Left_02", flags, R_FOOT, 13));
    mgr.bruce_left_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Left_03", flags, L_FOOT, 21));
    mgr.bruce_left_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Left_04", flags, R_FOOT, 18));
    mgr.bruce_left_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Left_05", flags, L_FOOT, 15));
    mgr.bruce_left_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Left_06", flags, R_FOOT, 12));
    mgr.bruce_left_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Left_07", flags, L_HAND, 15));
    mgr.bruce_left_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Left_08", flags, L_FOOT, 16));

    mgr.bruce_left_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Weak_Left", flags, R_HAND, 13));
    mgr.bruce_left_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Weak_Left_01", flags, R_HAND, 14));
    mgr.bruce_left_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Close_Weak_Left_02", flags, L_HAND, 13));

    mgr.bruce_left_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Far_Left", flags, L_FOOT, 22));
    mgr.bruce_left_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Far_Left_02", flags, R_ARM, 29));
    mgr.bruce_left_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Far_Left_03", flags, L_FOOT, 21));
    mgr.bruce_left_attack_motions.Push(Global_CreateMotion("BM_Attack/Attack_Far_Left_04", flags, L_FOOT, 30));

    // arm front
    mgr.bruce_counter_arm_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Front_01"));
    mgr.bruce_counter_arm_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Front_02"));
    mgr.bruce_counter_arm_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Front_03"));
    mgr.bruce_counter_arm_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Front_04"));
    mgr.bruce_counter_arm_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Front_05"));
    mgr.bruce_counter_arm_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Front_06"));
    mgr.bruce_counter_arm_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Front_07"));
    mgr.bruce_counter_arm_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Front_08"));
    mgr.bruce_counter_arm_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Front_09"));
    mgr.bruce_counter_arm_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Front_10"));
    mgr.bruce_counter_arm_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Front_13"));
    mgr.bruce_counter_arm_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Front_14"));
    mgr.bruce_counter_arm_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Front_Weak_02"));
    mgr.bruce_counter_arm_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Front_Weak_03"));
    mgr.bruce_counter_arm_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Front_Weak_04"));

    // leg front
    mgr.bruce_counter_leg_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Front_01"));
    mgr.bruce_counter_leg_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Front_02"));
    mgr.bruce_counter_leg_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Front_03"));
    mgr.bruce_counter_leg_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Front_04"));
    mgr.bruce_counter_leg_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Front_05"));
    mgr.bruce_counter_leg_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Front_06"));
    mgr.bruce_counter_leg_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Front_07"));
    mgr.bruce_counter_leg_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Front_08"));
    mgr.bruce_counter_leg_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Front_09"));
    mgr.bruce_counter_leg_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Front_Weak_01"));
    mgr.bruce_counter_leg_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Front_Weak_02"));
    mgr.bruce_counter_leg_front_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Front_Weak"));

    // arm back
    mgr.bruce_counter_arm_back_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Back_01"));
    mgr.bruce_counter_arm_back_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Back_02"));
    mgr.bruce_counter_arm_back_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Back_03"));
    mgr.bruce_counter_arm_back_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Back_05"));
    mgr.bruce_counter_arm_back_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Back_06"));
    mgr.bruce_counter_arm_back_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Back_Weak_01"));
    mgr.bruce_counter_arm_back_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Back_Weak_02"));
    mgr.bruce_counter_arm_back_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Arm_Back_Weak_03"));

    // leg back
    mgr.bruce_counter_leg_back_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Back_01"));
    mgr.bruce_counter_leg_back_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Back_02"));
    mgr.bruce_counter_leg_back_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Back_03"));
    mgr.bruce_counter_leg_back_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Back_04"));
    mgr.bruce_counter_leg_back_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Back_05"));
    mgr.bruce_counter_leg_back_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Back_Weak_01"));
    mgr.bruce_counter_leg_back_motions.Push(Global_CreateMotion("BM_TG_Counter/Counter_Leg_Back_Weak_03"));

    // double counter
    preFix = "BM_TG_Counter/";
    mgr.bruce_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsA"));
    mgr.bruce_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsB"));
    mgr.bruce_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsD"));
    mgr.bruce_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsE"));
    mgr.bruce_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsF"));
    mgr.bruce_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsG"));
    mgr.bruce_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsH"));

    // tripple counter
    mgr.bruce_counter_triple_motions.Push(Global_CreateMotion(preFix + "Double_Counter_3ThugsA"));
    mgr.bruce_counter_triple_motions.Push(Global_CreateMotion(preFix + "Double_Counter_3ThugsB"));
    mgr.bruce_counter_triple_motions.Push(Global_CreateMotion(preFix + "Double_Counter_3ThugsC"));

    // environment counter
    /*bruce_counter_environment_motions.Push(Global_CreateMotion(preFix + "Environment_Counter_128_Back_02"));
    bruce_counter_environment_motions.Push(Global_CreateMotion(preFix + "Environment_Counter_128_Front_01"));
    bruce_counter_environment_motions.Push(Global_CreateMotion(preFix + "Environment_Counter_128_Left_01"));
    bruce_counter_environment_motions.Push(Global_CreateMotion(preFix + "Environment_Counter_128_Right_01"));
    bruce_counter_environment_motions.Push(Global_CreateMotion(preFix + "Environment_Counter_128_Right_02"));*/
    mgr.bruce_counter_environment_motions.Push(Global_CreateMotion(preFix + "Environment_Counter_Wall_Back_02")); // wall (3.9,0,0) -90
    mgr.bruce_counter_environment_motions.Push(Global_CreateMotion(preFix + "Environment_Counter_Wall_Front_01")); // wall (0,0,-3) 0
    mgr.bruce_counter_environment_motions.Push(Global_CreateMotion(preFix + "Environment_Counter_Wall_Front_02")); // wall (0,0,-4.21) 0
    mgr.bruce_counter_environment_motions.Push(Global_CreateMotion(preFix + "Environment_Counter_Wall_Left_02")); // wall(0,0,-3.7) 0
    mgr.bruce_counter_environment_motions.Push(Global_CreateMotion(preFix + "Environment_Counter_Wall_Right")); // wall (0,0,-5.41) 180
    mgr.bruce_counter_environment_motions.Push(Global_CreateMotion(preFix + "Environment_Counter_Wall_Right_02")); // wall (0,0,4.05) 0

    preFix = "BM_Death_Primers/";
    Global_CreateMotion(preFix + "Death_Front");
    Global_CreateMotion(preFix + "Death_Back");
    Global_CreateMotion(preFix + "Death_Side_Left");
    Global_CreateMotion(preFix + "Death_Side_Right");
}

void AddBruceCombatAnimationTriggers()
{
    String preFix;

    // ===========================================================================
    //
    //   COUNTER TRIGGERS
    //
    // ===========================================================================
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
    String preFix;

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


// ==============================================
//
//    Bruce Class
//
// ==============================================

// -- non cost
float BRUCE_TRANSITION_DIST = 0.0f;
const String BRUCE_MOVEMENT_GROUP = "BM_Movement/";

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
        AddAttackMotion(rightAttacks, "Attack_Far_Right_02", 21, ATTACK_PUNCH, R_HAND);
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
        AddAttackMotion(backAttacks, "Attack_Close_Weak_Back_01", 12, ATTACK_PUNCH, R_HAND);

        AddAttackMotion(backAttacks, "Attack_Far_Back", 14, ATTACK_KICK, L_FOOT);
        AddAttackMotion(backAttacks, "Attack_Far_Back_01", 15, ATTACK_KICK, L_FOOT);
        AddAttackMotion(backAttacks, "Attack_Far_Back_02", 20, ATTACK_PUNCH, R_ARM);
        AddAttackMotion(backAttacks, "Attack_Far_Back_03", 30, ATTACK_PUNCH, L_HAND);
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
        AddAttackMotion(leftAttacks, "Attack_Far_Left_01", 24, ATTACK_KICK, R_FOOT);
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
    }

    void AddMotions()
    {
        String preFix = "BM_TG_Counter/";
        // Front Arm
        frontArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Front_Weak_02"));
        for(int i=1; i<=9; ++i)
            frontArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Front_0" + i));
        frontArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Front_10"));
        // Front Leg
        frontLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Front_Weak"));
        for(int i=1; i<=6; ++i)
            frontLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Front_0" + i));
        // Back Arm
        backArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Back_Weak_01"));
        for(int i=1; i<=4; ++i)
            frontArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Back_0" + i));
        // Back Leg
        backLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Back_Weak_01"));
        backLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Back_01"));
        backLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Back_02"));

        doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsA"));
        doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsB"));
        doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsD"));
        doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsE"));
        doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsF"));
        doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsG"));
        doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsH"));
        tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_3ThugsB"));
        tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_3ThugsC"));
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
    Global_CreateMotion(preFix + "Run_Right_Passing_To_Run_Right_180", kMotion_XZR, kMotion_ZR, 28);

    Global_CreateMotion(preFix + "Turn_Right_90", kMotion_R, kMotion_R, 16);
    Global_CreateMotion(preFix + "Turn_Right_180", kMotion_R, kMotion_R, 25);
    Global_CreateMotion(preFix + "Turn_Left_90", kMotion_R, kMotion_R, 14);
    Global_CreateMotion(preFix + "Walk_Forward", kMotion_Z, kMotion_Z, -1, true);

    Global_CreateMotion(preFix + "Stand_To_Walk_Right_90", kMotion_XZR, kMotion_ZR, 21);
    Global_CreateMotion(preFix + "Stand_To_Walk_Right_180", kMotion_XZR, kMotion_ZR, 25);
    Global_CreateMotion(preFix + "Stand_To_Run_Right_90", kMotion_XZR, kMotion_ZR, 18);
    Global_CreateMotion(preFix + "Stand_To_Run_Right_180", kMotion_XZR, kMotion_ZR, 25);

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

    Global_CreateMotion_InFolder("BM_Attack/");
    Global_CreateMotion_InFolder("BM_TG_Counter/");

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
    for (uint i=1; i<=6; ++i)
        Global_CreateMotion(preFix + "Beatdown_Test_0" + i);

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

    AddBruceCombatAnimationTriggers();
}


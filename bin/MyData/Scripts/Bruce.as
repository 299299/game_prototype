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

class BruceMoveState : PlayerMoveState
{
    BruceMoveState(Character@ c)
    {
        super(c);
        SetMotion("BW_Movement/Walk_Forward");
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
        String preFix = "BW_TG_Counter/";
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
        backArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Back_01"));
        backArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Back_02"));
        backArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Back_03"));
        backArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Back_04"));
        // Back Leg
        backLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Back_Weak_01"));
        backLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Back_01"));
        backLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Back_02"));

        /*
        doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsA"));
        doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsB"));
        doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsC"));
        doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsD"));
        doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsE"));
        doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsF"));
        doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsG"));
        doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsH"));

        tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_3ThugsA"));
        tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_3ThugsB"));
        tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_3ThugsC"));
        */
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

void CreateBruceMotions()
{
    AssignMotionRig("Models/bruce_w.mdl");

    String preFix = "BW_Movement/";
    Global_CreateMotion(preFix + "Turn_Right_90", kMotion_XZR, kMotion_R, 16);
    Global_CreateMotion(preFix + "Turn_Right_180", kMotion_XZR, kMotion_R, 25);
    Global_CreateMotion(preFix + "Turn_Left_90", kMotion_XZR, kMotion_R, 14);
    Global_CreateMotion(preFix + "Walk_Forward", kMotion_XZR, kMotion_Z, -1, true);

    Global_AddAnimation("BM_Movement/Stand_Idle");

    preFix = "BM_HitReaction/";
    Global_CreateMotion(preFix + "HitReaction_Back"); // back attacked
    Global_CreateMotion(preFix + "HitReaction_Face_Right"); // front punched
    Global_CreateMotion(preFix + "Hit_Reaction_SideLeft"); // left attacked
    Global_CreateMotion(preFix + "Hit_Reaction_SideRight"); // right attacked

    Global_CreateMotion_InFolder("BW_Attack/");
    Global_CreateMotion_InFolder("BW_TG_Counter/");

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

    preFix = "BM_Combat/";
    Global_CreateMotion(preFix + "Into_Takedown");
    Global_CreateMotion(preFix + "Evade_Forward_01");
    Global_CreateMotion(preFix + "Evade_Back_01");
    Global_CreateMotion(preFix + "Evade_Left_01");
    Global_CreateMotion(preFix + "Evade_Right_01");
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

    preFix = "BM_Attack/";
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
    AddStringAnimationTrigger(preFix + "Counter_Arm_Back_01", 9, COMBAT_SOUND, R_ARM);
    AddStringAnimationTrigger(preFix + "Counter_Arm_Back_01", 38, COMBAT_SOUND, R_ARM);
    AddAnimationTrigger(preFix + "Counter_Arm_Back_01", 40, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Counter_Arm_Back_02", 8, COMBAT_SOUND, R_HAND);
    AddStringAnimationTrigger(preFix + "Counter_Arm_Back_02", 41, COMBAT_SOUND, R_FOOT);
    AddAnimationTrigger(preFix + "Counter_Arm_Back_02", 43, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Counter_Arm_Back_03", 6, COMBAT_SOUND, R_ARM);
    AddStringAnimationTrigger(preFix + "Counter_Arm_Back_03", 17, COMBAT_SOUND, R_ARM);
    AddStringAnimationTrigger(preFix + "Counter_Arm_Back_03", 33, COMBAT_SOUND, L_FOOT);
    AddAnimationTrigger(preFix + "Counter_Arm_Back_03", 35, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Counter_Arm_Back_04", 14, COMBAT_SOUND, R_HAND);
    AddStringAnimationTrigger(preFix + "Counter_Arm_Back_04", 28, COMBAT_SOUND, R_CALF);
    AddAnimationTrigger(preFix + "Counter_Arm_Back_04", 40, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Counter_Arm_Back_Weak_01", 11, COMBAT_SOUND, R_ARM);
    AddStringAnimationTrigger(preFix + "Counter_Arm_Back_Weak_01", 25, COMBAT_SOUND, R_ARM);
    AddAnimationTrigger(preFix + "Counter_Arm_Back_Weak_01", 27, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Counter_Arm_Front_01", 9, COMBAT_SOUND, R_HAND);
    AddStringAnimationTrigger(preFix + "Counter_Arm_Front_01", 17, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(preFix + "Counter_Arm_Front_01", 34, COMBAT_SOUND, R_FOOT);
    AddAnimationTrigger(preFix + "Counter_Arm_Front_01", 36, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Counter_Arm_Front_02", 9, COMBAT_SOUND, R_ARM);
    AddStringAnimationTrigger(preFix + "Counter_Arm_Front_02", 22, COMBAT_SOUND, R_ARM);
    AddStringAnimationTrigger(preFix + "Counter_Arm_Front_02", 45, COMBAT_SOUND, R_HAND);
    AddAnimationTrigger(preFix + "Counter_Arm_Front_02", 47, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Counter_Arm_Front_03", 9, COMBAT_SOUND, R_ARM);
    AddStringAnimationTrigger(preFix + "Counter_Arm_Front_03", 39, COMBAT_SOUND, R_HAND);
    AddAnimationTrigger(preFix + "Counter_Arm_Front_03", 41, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Counter_Arm_Front_04", 12, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(preFix + "Counter_Arm_Front_04", 34, COMBAT_SOUND, R_ARM);
    AddAnimationTrigger(preFix + "Counter_Arm_Front_03", 41, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Counter_Arm_Front_05", 7, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(preFix + "Counter_Arm_Front_05", 26, COMBAT_SOUND, R_HAND);
    AddStringAnimationTrigger(preFix + "Counter_Arm_Front_05", 43, COMBAT_SOUND, L_HAND);
    AddAnimationTrigger(preFix + "Counter_Arm_Front_05", 45, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Counter_Arm_Front_06", 5, COMBAT_SOUND, R_ARM);
    AddStringAnimationTrigger(preFix + "Counter_Arm_Front_06", 18, COMBAT_SOUND, R_FOOT);
    AddStringAnimationTrigger(preFix + "Counter_Arm_Front_06", 38, COMBAT_SOUND, L_HAND);
    AddAnimationTrigger(preFix + "Counter_Arm_Front_06", 40, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Counter_Arm_Front_07", 6, COMBAT_SOUND, R_HAND);
    AddStringAnimationTrigger(preFix + "Counter_Arm_Front_07", 24, COMBAT_SOUND, L_HAND);
    AddAnimationTrigger(preFix + "Counter_Arm_Front_07", 26, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Counter_Arm_Front_08", 4, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(preFix + "Counter_Arm_Front_08", 11, COMBAT_SOUND, R_HAND);
    AddStringAnimationTrigger(preFix + "Counter_Arm_Front_08", 30, COMBAT_SOUND, R_ARM);
    AddAnimationTrigger(preFix + "Counter_Arm_Front_08", 32, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Counter_Arm_Front_09", 6, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(preFix + "Counter_Arm_Front_09", 22, COMBAT_SOUND, L_ARM);
    AddStringAnimationTrigger(preFix + "Counter_Arm_Front_09", 39, COMBAT_SOUND, R_HAND);
    AddAnimationTrigger(preFix + "Counter_Arm_Front_09", 41, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Counter_Arm_Front_10", 10, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(preFix + "Counter_Arm_Front_10", 23, COMBAT_SOUND, L_FOOT);
    AddAnimationTrigger(preFix + "Counter_Arm_Front_10", 25, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Counter_Arm_Front_Weak_02", 4, COMBAT_SOUND, L_ARM);
    AddStringAnimationTrigger(preFix + "Counter_Arm_Front_Weak_02", 9, COMBAT_SOUND, R_HAND);
    AddStringAnimationTrigger(preFix + "Counter_Arm_Front_Weak_02", 21, COMBAT_SOUND, L_HAND);
    AddAnimationTrigger(preFix + "Counter_Arm_Front_Weak_02", 23, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Counter_Leg_Back_01", 9, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(preFix + "Counter_Leg_Back_01", 17, COMBAT_SOUND, L_FOOT);
    AddStringAnimationTrigger(preFix + "Counter_Leg_Back_01", 46, COMBAT_SOUND, R_ARM);
    AddAnimationTrigger(preFix + "Counter_Leg_Back_01", 48, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Counter_Leg_Back_02", 7, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(preFix + "Counter_Leg_Back_02", 15, COMBAT_SOUND, R_ARM);
    AddStringAnimationTrigger(preFix + "Counter_Leg_Back_02", 46, COMBAT_SOUND, L_CALF);
    AddAnimationTrigger(preFix + "Counter_Leg_Back_02", 48, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Counter_Leg_Back_Weak_01", 7, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(preFix + "Counter_Leg_Back_Weak_01", 30, COMBAT_SOUND, R_ARM);
    AddAnimationTrigger(preFix + "Counter_Leg_Back_Weak_01", 32, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Counter_Leg_Front_01", 11, COMBAT_SOUND, L_FOOT);
    AddStringAnimationTrigger(preFix + "Counter_Leg_Front_01", 30, COMBAT_SOUND, L_FOOT);
    AddAnimationTrigger(preFix + "Counter_Leg_Front_01", 32, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Counter_Leg_Front_02", 6, COMBAT_SOUND, R_HAND);
    AddStringAnimationTrigger(preFix + "Counter_Leg_Front_02", 15, COMBAT_SOUND, R_ARM);
    AddStringAnimationTrigger(preFix + "Counter_Leg_Front_02", 42, COMBAT_SOUND, L_CALF);
    AddAnimationTrigger(preFix + "Counter_Leg_Front_02", 44, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Counter_Leg_Front_03", 3, COMBAT_SOUND, R_ARM);
    AddStringAnimationTrigger(preFix + "Counter_Leg_Front_03", 22, COMBAT_SOUND, L_HAND);
    AddAnimationTrigger(preFix + "Counter_Leg_Front_03", 24, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Counter_Leg_Front_04", 7, COMBAT_SOUND, L_FOOT);
    AddStringAnimationTrigger(preFix + "Counter_Leg_Front_04", 30, COMBAT_SOUND, R_FOOT);
    AddAnimationTrigger(preFix + "Counter_Leg_Front_04", 32, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Counter_Leg_Front_05", 5, COMBAT_SOUND, L_FOOT);
    AddStringAnimationTrigger(preFix + "Counter_Leg_Front_05", 18, COMBAT_SOUND, L_FOOT);
    AddStringAnimationTrigger(preFix + "Counter_Leg_Front_05", 38, COMBAT_SOUND, R_FOOT);
    AddAnimationTrigger(preFix + "Counter_Leg_Front_05", 40, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Counter_Leg_Front_06", 6, COMBAT_SOUND, R_HAND);
    AddStringAnimationTrigger(preFix + "Counter_Leg_Front_06", 18, COMBAT_SOUND, L_HAND);
    AddAnimationTrigger(preFix + "Counter_Leg_Front_06", 20, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Counter_Leg_Front_Weak", 12, COMBAT_SOUND, L_FOOT);
    AddStringAnimationTrigger(preFix + "Counter_Leg_Front_Weak", 18, COMBAT_SOUND, L_FOOT);
    AddAnimationTrigger(preFix + "Counter_Leg_Front_Weak", 20, READY_TO_FIGHT);

    /*
    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsA", 12, IMPACT, L_HAND);
    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsA", 12, PARTICLE, R_HAND);
    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsA", 77, IMPACT, L_HAND);
    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsA", 77, PARTICLE, R_HAND);
    AddAnimationTrigger(preFix + "Double_Counter_2ThugsA", 79, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsB", 12, IMPACT, L_HAND);
    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsB", 36, IMPACT, L_HAND);
    AddAnimationTrigger(preFix + "Double_Counter_2ThugsB", 60, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsD", 7, IMPACT, L_HAND);
    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsD", 7, PARTICLE, R_HAND);
    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsD", 15, IMPACT, L_HAND);
    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsD", 38, IMPACT, L_HAND);
    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsD", 38, PARTICLE, R_HAND);
    AddAnimationTrigger(preFix + "Double_Counter_2ThugsD", 43, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsE", 21, IMPACT, R_ARM);
    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsE", 43, IMPACT, L_FOOT);
    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsE", 76, IMPACT, L_HAND);
    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsE", 83, IMPACT, L_HAND);
    AddAnimationTrigger(preFix + "Double_Counter_2ThugsE", 85, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsF", 26, IMPACT, L_FOOT);
    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsF", 26, PARTICLE, R_FOOT);
    AddAnimationTrigger(preFix + "Double_Counter_2ThugsF", 60, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsG", 23, IMPACT, L_HAND);
    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsG", 23, PARTICLE, R_HAND);
    AddAnimationTrigger(preFix + "Double_Counter_2ThugsG", 25, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsH", 21, IMPACT, L_HAND);
    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsH", 21, PARTICLE, R_HAND);
    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsH", 36, IMPACT, L_HAND);
    AddStringAnimationTrigger(preFix + "Double_Counter_2ThugsH", 36, PARTICLE, R_HAND);
    AddAnimationTrigger(preFix + "Double_Counter_2ThugsH", 65, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Double_Counter_3ThugsA", 5, IMPACT, L_HAND);
    AddStringAnimationTrigger(preFix + "Double_Counter_3ThugsA", 7, IMPACT, R_HAND);
    AddStringAnimationTrigger(preFix + "Double_Counter_3ThugsA", 26, IMPACT, R_HAND);
    AddAnimationTrigger(preFix + "Double_Counter_3ThugsA", 35, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Double_Counter_3ThugsB", 27, IMPACT, R_HAND);
    AddStringAnimationTrigger(preFix + "Double_Counter_3ThugsB", 27, PARTICLE, L_FOOT);
    AddStringAnimationTrigger(preFix + "Double_Counter_3ThugsB", 27, PARTICLE, R_FOOT);
    AddAnimationTrigger(preFix + "Double_Counter_3ThugsB", 50, READY_TO_FIGHT);

    AddStringAnimationTrigger(preFix + "Double_Counter_3ThugsC", 5, IMPACT, L_HAND);
    AddStringAnimationTrigger(preFix + "Double_Counter_3ThugsC", 5, PARTICLE, R_HAND);
    AddStringAnimationTrigger(preFix + "Double_Counter_3ThugsC", 37, IMPACT, R_HAND);
    AddStringAnimationTrigger(preFix + "Double_Counter_3ThugsC", 37, PARTICLE, L_FOOT);
    AddAnimationTrigger(preFix + "Double_Counter_3ThugsC", 52, READY_TO_FIGHT);
    */
}

class Bruce : Player
{
    void AddStates()
    {
        stateMachine.AddState(BruceStandState(this));
        stateMachine.AddState(BruceTurnState(this));
        stateMachine.AddState(BruceMoveState(this));
        stateMachine.AddState(BruceAttackState(this));
        stateMachine.AddState(BruceCounterState(this));
        stateMachine.AddState(BruceEvadeState(this));
        stateMachine.AddState(BruceHitState(this));
        stateMachine.AddState(BruceDeadState(this));
        stateMachine.AddState(BruceBeatDownHitState(this));
        stateMachine.AddState(BruceBeatDownEndState(this));
        stateMachine.AddState(BruceTransitionState(this));
        stateMachine.AddState(AnimationTestState(this));
    }
};
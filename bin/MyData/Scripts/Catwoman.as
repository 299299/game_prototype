// ==============================================
//
//    Catwoman Class
//
// ==============================================

// -- non cost
float CATWOMAN_TRANSITION_DIST = 0.0f;

class CatwomanStandState : PlayerStandState
{
    CatwomanStandState(Character@ c)
    {
        super(c);
        animations.Push(GetAnimationName("CW_Movement/Stand_Idle"));
        flags = FLAGS_ATTACK;
    }
};

class CatwomanTurnState : PlayerTurnState
{
    CatwomanTurnState(Character@ c)
    {
        super(c);
        AddMotion("CW_Movement/Turn_Right_90");
        AddMotion("CW_Movement/Turn_Right_180");
        AddMotion("CW_Movement/Turn_Left_90");
    }
};

class CatwomanMoveState : PlayerMoveState
{
    CatwomanMoveState(Character@ c)
    {
        super(c);
        SetMotion("CW_Movement/Walk_Forward");
    }
};

class CatwomanEvadeState : PlayerEvadeState
{
    CatwomanEvadeState(Character@ c)
    {
        super(c);
        String prefix = "CW_Combat/";
        AddMotion(prefix + "Evade_Forward_01");
        AddMotion(prefix + "Evade_Right_01");
        AddMotion(prefix + "Evade_Back_01");
        AddMotion(prefix + "Evade_Left_01");
    }
};

class CatwomanAttackState : PlayerAttackState
{
    CatwomanAttackState(Character@ c)
    {
        super(c);

        //========================================================================
        // BACK
        //========================================================================
        AddAttackMotion(backAttacks, "Attack_Close_Weak_Back_01", 16, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(backAttacks, "Attack_Close_Back_01", 19, ATTACK_KICK, L_FOOT);
        AddAttackMotion(backAttacks, "Attack_Close_Back_02", 21, ATTACK_KICK, R_FOOT);
        AddAttackMotion(backAttacks, "Attack_Close_Back_03", 13, ATTACK_KICK, L_FOOT);
        AddAttackMotion(backAttacks, "Attack_Close_Back_04", 12, ATTACK_KICK, R_FOOT);
        AddAttackMotion(backAttacks, "Attack_Far_Back_01", 39, ATTACK_KICK, L_FOOT);
        AddAttackMotion(backAttacks, "Attack_Far_Back_02", 31, ATTACK_KICK, L_FOOT);
        AddAttackMotion(backAttacks, "Attack_Far_Back_03", 27, ATTACK_KICK, L_FOOT);

        //========================================================================
        // FORWARD
        //========================================================================
        AddAttackMotion(forwardAttacks, "Attack_Close_Weak_Forward_01", 11, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Close_Weak_Forward_02", 13, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Close_Weak_Forward_03", 12, ATTACK_KICK, L_FOOT);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_01", 11, ATTACK_KICK, R_FOOT);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_03", 12, ATTACK_KICK, R_FOOT);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_04", 21, ATTACK_KICK, R_FOOT);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_05", 12, ATTACK_KICK, L_FOOT);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_06", 20, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_07", 14, ATTACK_KICK, L_FOOT);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_08", 15, ATTACK_KICK, R_FOOT);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_09", 17, ATTACK_KICK, R_FOOT);
        AddAttackMotion(forwardAttacks, "Attack_Run_Close_Forward", 13, ATTACK_KICK, R_FOOT);
        AddAttackMotion(forwardAttacks, "Attack_Far_Forward_01", 41, ATTACK_KICK, R_FOOT);
        AddAttackMotion(forwardAttacks, "Attack_Far_Forward_02", 29, ATTACK_KICK, L_FOOT);
        AddAttackMotion(forwardAttacks, "Attack_Far_Forward_03", 42, ATTACK_KICK, R_FOOT);
        AddAttackMotion(forwardAttacks, "Attack_Run_Far_Forward", 29, ATTACK_KICK, L_FOOT);

        //========================================================================
        // LEFT
        //========================================================================
        AddAttackMotion(leftAttacks, "Attack_Close_Weak_Left_01", 10, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(leftAttacks, "Attack_Close_Weak_Left_02", 13, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_01", 12, ATTACK_KICK, R_FOOT);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_02", 20, ATTACK_KICK, L_FOOT);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_03", 14, ATTACK_KICK, L_FOOT);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_04", 12, ATTACK_KICK, R_FOOT);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_05", 15, ATTACK_KICK, L_FOOT);
        AddAttackMotion(leftAttacks, "Attack_Far_Left_01", 34, ATTACK_KICK, R_FOOT);
        AddAttackMotion(leftAttacks, "Attack_Far_Left_02", 30, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(leftAttacks, "Attack_Far_Left_03", 22, ATTACK_KICK, L_FOOT);

        //========================================================================
        // RIGHT
        //========================================================================
        // right weak
        AddAttackMotion(rightAttacks, "Attack_Close_Weak_Right_01", 14, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(rightAttacks, "Attack_Close_Weak_Right_02", 14, ATTACK_KICK, L_FOOT);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_01", 15, ATTACK_KICK, R_FOOT);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_02", 21, ATTACK_KICK, R_FOOT);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_03", 15, ATTACK_KICK, L_CALF);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_04", 20, ATTACK_KICK, R_FOOT);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_05", 18, ATTACK_PUNCH, R_ARM);
        AddAttackMotion(rightAttacks, "Attack_Far_Right_01", 36, ATTACK_KICK, L_FOOT);
        AddAttackMotion(rightAttacks, "Attack_Far_Right_02", 27, ATTACK_KICK, R_FOOT);

        PostInit();
    }

    void AddAttackMotion(Array<AttackMotion@>@ attacks, const String&in name, int frame, int type, const String&in bName)
    {
        attacks.Push(AttackMotion("CW_Attack/" + name, frame, type, bName));
    }
};


class CatwomanCounterState : PlayerCounterState
{
    CatwomanCounterState(Character@ c)
    {
        super(c);
        AddCW_Counter_Animations("CW_TG_Counter/", true);
    }
};

class CatwomanHitState : PlayerHitState
{
    CatwomanHitState(Character@ c)
    {
        super(c);
        String hitPrefix = "CW_Hit_Reaction/";
        AddMotion(hitPrefix + "HitReaction_Face_Left");
        AddMotion(hitPrefix + "Hit_Reaction_SideLeft");
        AddMotion(hitPrefix + "HitReaction_Back");
        AddMotion(hitPrefix + "Hit_Reaction_SideRight");
    }
};

class CatwomanDeadState : PlayerDeadState
{
    CatwomanDeadState(Character@ c)
    {
        super(c);
        String prefix = "CW_Death_Primers/";
        AddMotion(prefix + "Death_Front");
        AddMotion(prefix + "Death_Side_Left");
        AddMotion(prefix + "Death_Back");
        AddMotion(prefix + "Death_Side_Right");
    }
};

class CatwomanBeatDownEndState : PlayerBeatDownEndState
{
    CatwomanBeatDownEndState(Character@ c)
    {
        super(c);
        String preFix = "CW_TG_Beatdown/";
        AddMotion(preFix + "Beatdown_End_01");
        AddMotion(preFix + "Beatdown_End_02");
        AddMotion(preFix + "Beatdown_End_03");
    }
};

class CatwomanBeatDownHitState : PlayerBeatDownHitState
{
    CatwomanBeatDownHitState(Character@ c)
    {
        super(c);
        String preFix = "CW_Attack/";
        AddMotion(preFix + "Beatdown_01");
        AddMotion(preFix + "Beatdown_02");
        AddMotion(preFix + "Beatdown_03");
        AddMotion(preFix + "Beatdown_04");
        AddMotion(preFix + "Beatdown_05");
        AddMotion(preFix + "Beatdown_06");
    }

    bool IsTransitionNeeded(float curDist)
    {
        return curDist > CATWOMAN_TRANSITION_DIST + 0.5f;
    }
};

class CatwomanTransitionState : PlayerTransitionState
{
    CatwomanTransitionState(Character@ c)
    {
        super(c);
        SetMotion("CW_Combat/Into_Takedown");
        if (motion !is null)
            CATWOMAN_TRANSITION_DIST = motion.endDistance;
        Print("Catwoman-Transition Dist=" + CATWOMAN_TRANSITION_DIST);
    }
};

class Catwoman : Player
{
    void AddStates()
    {
        stateMachine.AddState(CatwomanStandState(this));
        stateMachine.AddState(CatwomanTurnState(this));
        stateMachine.AddState(CatwomanMoveState(this));
        stateMachine.AddState(CatwomanEvadeState(this));
        stateMachine.AddState(CatwomanAttackState(this));
        stateMachine.AddState(CatwomanCounterState(this));
        stateMachine.AddState(CatwomanHitState(this));
        stateMachine.AddState(CatwomanDeadState(this));
        stateMachine.AddState(CatwomanBeatDownHitState(this));
        stateMachine.AddState(CatwomanBeatDownEndState(this));
        stateMachine.AddState(CatwomanTransitionState(this));
        stateMachine.AddState(AnimationTestState(this));
    }
};

void CreateCatwomanMotions()
{
    AssignMotionRig("Models/catwoman.mdl");

    String preFix = "CW_Movement/";

    Global_CreateMotion(preFix + "Turn_Right_90", kMotion_XZR, kMotion_R, 16);
    Global_CreateMotion(preFix + "Turn_Right_180", kMotion_XZR, kMotion_R, 25);
    Global_CreateMotion(preFix + "Turn_Left_90", kMotion_XZR, kMotion_R, 14);
    Global_CreateMotion(preFix + "Walk_Forward", kMotion_XZR, kMotion_Z, -1, true);

    preFix = "CW_Combat/";
    Global_CreateMotion(preFix + "Evade_Forward_01");
    Global_CreateMotion(preFix + "Evade_Back_01");
    Global_CreateMotion(preFix + "Evade_Left_01");
    Global_CreateMotion(preFix + "Evade_Right_01");
    Global_CreateMotion(preFix + "Into_Takedown");

    Global_CreateMotion_InFolder("CW_Attack/");

    preFix = "CW_TG_Beatdown/";
    Global_CreateMotion(preFix + "Beatdown_End_01");
    Global_CreateMotion(preFix + "Beatdown_End_02");
    Global_CreateMotion(preFix + "Beatdown_End_03");

    preFix = "CW_Hit_Reaction/";
    Global_CreateMotion(preFix + "HitReaction_Face_Left");
    Global_CreateMotion(preFix + "Hit_Reaction_SideLeft");
    Global_CreateMotion(preFix + "Hit_Reaction_SideRight");
    Global_CreateMotion(preFix + "HitReaction_Back");

    preFix = "CW_Death_Primers/";
    Global_CreateMotion(preFix + "Death_Front");
    Global_CreateMotion(preFix + "Death_Side_Left");
    Global_CreateMotion(preFix + "Death_Back");
    Global_CreateMotion(preFix + "Death_Side_Right");

    Global_CreateMotion_InFolder("CW_TG_Counter/");

    preFix = "CW_Movement/";
    Global_AddAnimation(preFix + "Stand_Idle");
}

void AddCatwomanAnimationTriggers()
{
    String preFix = "CW_Movement/";

    AddStringAnimationTrigger(preFix + "Walk_Forward", 4, FOOT_STEP, R_FOOT);
    AddStringAnimationTrigger(preFix + "Walk_Forward", 18, FOOT_STEP, L_FOOT);
    AddStringAnimationTrigger(preFix + "Walk_Forward", 32, FOOT_STEP, R_FOOT);
    AddStringAnimationTrigger(preFix + "Walk_Forward", 44, FOOT_STEP, L_FOOT);

    preFix = "CW_Combat/";
    AddAnimationTrigger(preFix + "Evade_Forward_01", 58, READY_TO_FIGHT);
    AddAnimationTrigger(preFix + "Evade_Back_01", 32, READY_TO_FIGHT);
    AddAnimationTrigger(preFix + "Evade_Left_01", 50, READY_TO_FIGHT);
    AddAnimationTrigger(preFix + "Evade_Right_01", 48, READY_TO_FIGHT);

    preFix = "CW_Attack/";
    int beat_impact_frame = 4;
    AddStringAnimationTrigger(preFix + "Beatdown_01", beat_impact_frame, IMPACT, L_HAND);
    AddStringAnimationTrigger(preFix + "Beatdown_02", beat_impact_frame, IMPACT, R_HAND);
    AddStringAnimationTrigger(preFix + "Beatdown_03", beat_impact_frame, IMPACT, R_HAND);
    AddStringAnimationTrigger(preFix + "Beatdown_04", beat_impact_frame, IMPACT, R_HAND);
    AddStringAnimationTrigger(preFix + "Beatdown_05", beat_impact_frame, IMPACT, L_HAND);
    AddStringAnimationTrigger(preFix + "Beatdown_06", beat_impact_frame, IMPACT, L_HAND);

    preFix = "CW_TG_Beatdown/";
    AddStringAnimationTrigger(preFix + "Beatdown_End_01", 22, IMPACT, HEAD);
    AddStringAnimationTrigger(preFix + "Beatdown_End_02", 24, IMPACT, R_CALF);
    AddStringAnimationTrigger(preFix + "Beatdown_End_03", 29, IMPACT, R_FOOT);

    preFix = "CW_Hit_Reaction/";
    AddAnimationTrigger(preFix + "HitReaction_Face_Left", 80, READY_TO_FIGHT);
    AddAnimationTrigger(preFix + "Hit_Reaction_SideLeft", 46, READY_TO_FIGHT);
    AddAnimationTrigger(preFix + "Hit_Reaction_SideRight", 51, READY_TO_FIGHT);
    AddAnimationTrigger(preFix + "HitReaction_Back", 52, READY_TO_FIGHT);

    // ===========================================================================
    //
    //   COUNTER TRIGGERS
    //
    // ===========================================================================
    preFix = "CW_TG_Counter/";
    String animName = preFix + "Counter_Arm_Back_01";
    AddStringAnimationTrigger(animName, 8, COMBAT_SOUND, R_HAND);
    AddStringAnimationTrigger(animName, 37, COMBAT_SOUND, HEAD);
    AddStringAnimationTrigger(animName, 56, COMBAT_SOUND, R_HAND);
    AddAnimationTrigger(animName, 56, READY_TO_FIGHT);

    animName = preFix + "Counter_Arm_Back_02";
    AddStringAnimationTrigger(animName, 5, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 32, COMBAT_SOUND, R_HAND);
    AddStringAnimationTrigger(animName, 59, COMBAT_SOUND, R_CALF);
    AddAnimationTrigger(animName, 70, READY_TO_FIGHT);

    animName = preFix + "Counter_Arm_Back_03";
    AddStringAnimationTrigger(animName, 20, COMBAT_SOUND, L_FOOT);
    AddStringAnimationTrigger(animName, 29, COMBAT_SOUND, R_FOOT);
    AddAnimationTrigger(animName, 50, READY_TO_FIGHT);

    animName = preFix + "Counter_Arm_Back_Weak_01";
    AddStringAnimationTrigger(animName, 17, COMBAT_SOUND, L_FOOT);
    AddAnimationTrigger(animName, 47, READY_TO_FIGHT);

    animName = preFix + "Counter_Arm_Back_Weak_02";
    AddStringAnimationTrigger(animName, 8, COMBAT_SOUND, R_HAND);
    AddStringAnimationTrigger(animName, 19, COMBAT_SOUND, R_CALF);
    AddAnimationTrigger(animName, 40, READY_TO_FIGHT);

    animName = preFix + "Counter_Arm_Front_01";
    AddStringAnimationTrigger(animName, 11, COMBAT_SOUND, R_FOOT);
    AddAnimationTrigger(animName, 30, READY_TO_FIGHT);

    animName = preFix + "Counter_Arm_Front_02";
    AddStringAnimationTrigger(animName, 5, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 27, COMBAT_SOUND, L_FOOT);
    AddAnimationTrigger(animName, 50, READY_TO_FIGHT);

    animName = preFix + "Counter_Arm_Front_03";
    AddStringAnimationTrigger(animName, 23, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 39, COMBAT_SOUND, R_CALF);
    AddAnimationTrigger(animName, 56, READY_TO_FIGHT);

    animName = preFix + "Counter_Arm_Front_04";
    AddStringAnimationTrigger(animName, 10, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 18, COMBAT_SOUND, L_FOOT);
    AddStringAnimationTrigger(animName, 42, COMBAT_SOUND, R_FOOT);
    AddAnimationTrigger(animName, 52, READY_TO_FIGHT);

    animName = preFix + "Counter_Arm_Front_05";
    AddStringAnimationTrigger(animName, 21, COMBAT_SOUND, R_HAND);
    AddStringAnimationTrigger(animName, 43, COMBAT_SOUND, R_CALF);
    AddAnimationTrigger(animName, 60, READY_TO_FIGHT);

    animName = preFix + "Counter_Arm_Front_Weak_01";
    AddStringAnimationTrigger(animName, 7, COMBAT_SOUND, R_HAND);
    AddStringAnimationTrigger(animName, 20, COMBAT_SOUND, L_ARM);
    AddAnimationTrigger(animName, 32, READY_TO_FIGHT);

    animName = preFix + "Counter_Arm_Front_Weak_02";
    AddStringAnimationTrigger(animName, 16, COMBAT_SOUND, R_HAND);
    AddStringAnimationTrigger(animName, 42, COMBAT_SOUND, R_FOOT);
    AddAnimationTrigger(animName, 60, READY_TO_FIGHT);

    animName = preFix + "Counter_Leg_Back_01";
    AddStringAnimationTrigger(animName, 5, COMBAT_SOUND, L_FOOT);
    AddStringAnimationTrigger(animName, 18, COMBAT_SOUND, L_FOOT);
    AddAnimationTrigger(animName, 25, READY_TO_FIGHT);

    animName = preFix + "Counter_Leg_Back_01";
    AddStringAnimationTrigger(animName, 5, COMBAT_SOUND, L_FOOT);
    AddStringAnimationTrigger(animName, 18, COMBAT_SOUND, L_FOOT);
    AddAnimationTrigger(animName, 26, READY_TO_FIGHT);

    animName = preFix + "Counter_Leg_Back_02";
    AddStringAnimationTrigger(animName, 21, COMBAT_SOUND, R_HAND);
    AddStringAnimationTrigger(animName, 32, COMBAT_SOUND, R_FOOT);
    AddStringAnimationTrigger(animName, 63, COMBAT_SOUND, L_FOOT);
    AddAnimationTrigger(animName, 80, READY_TO_FIGHT);

    animName = preFix + "Counter_Leg_Back_Weak_01";
    AddStringAnimationTrigger(animName, 17, COMBAT_SOUND, R_HAND);
    AddStringAnimationTrigger(animName, 35, COMBAT_SOUND, HEAD);
    AddAnimationTrigger(animName, 45, READY_TO_FIGHT);

    animName = preFix + "Counter_Leg_Back_Weak_02";
    AddStringAnimationTrigger(animName, 24, COMBAT_SOUND, R_HAND);
    AddStringAnimationTrigger(animName, 32, COMBAT_SOUND, R_FOOT);
    AddAnimationTrigger(animName, 52, READY_TO_FIGHT);

    animName = preFix + "Counter_Leg_Front_01";
    AddStringAnimationTrigger(animName, 6, COMBAT_SOUND, R_HAND);
    AddStringAnimationTrigger(animName, 13, COMBAT_SOUND, R_FOOT);
    AddAnimationTrigger(animName, 30, READY_TO_FIGHT);

    animName = preFix + "Counter_Leg_Front_03";
    AddStringAnimationTrigger(animName, 9, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 27, COMBAT_SOUND, L_ARM);
    AddStringAnimationTrigger(animName, 43, COMBAT_SOUND, R_HAND);
    AddAnimationTrigger(animName, 72, READY_TO_FIGHT);

    animName = preFix + "Counter_Leg_Front_04";
    AddStringAnimationTrigger(animName, 10, COMBAT_SOUND, R_HAND);
    AddStringAnimationTrigger(animName, 40, COMBAT_SOUND, R_FOOT);
    AddAnimationTrigger(animName, 60, READY_TO_FIGHT);

    animName = preFix + "Counter_Leg_Front_Weak_01";
    AddStringAnimationTrigger(animName, 8, COMBAT_SOUND, L_FOOT);
    AddAnimationTrigger(animName, 25, READY_TO_FIGHT);

    animName = preFix + "Counter_Leg_Front_Weak_02";
    AddStringAnimationTrigger(animName, 8, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 26, COMBAT_SOUND, L_FOOT);
    AddAnimationTrigger(animName, 50, READY_TO_FIGHT);

    animName = preFix + "Double_Counter_2ThugsA";
    AddStringAnimationTrigger(animName, 5, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 18, COMBAT_SOUND, R_FOOT);
    AddStringAnimationTrigger(animName, 40, COMBAT_SOUND, L_FOOT);
    AddAnimationTrigger(animName, 60, READY_TO_FIGHT);

    animName = preFix + "Double_Counter_2ThugsB";
    AddStringAnimationTrigger(animName, 4, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 31, COMBAT_SOUND, R_FOOT);
    AddAnimationTrigger(animName, 50, READY_TO_FIGHT);

    animName = preFix + "Double_Counter_2ThugsC";
    AddStringAnimationTrigger(animName, 22, COMBAT_SOUND, R_CALF);
    AddStringAnimationTrigger(animName, 28, COMBAT_SOUND, R_FOOT);
    AddAnimationTrigger(animName, 45, READY_TO_FIGHT);

    animName = preFix + "Double_Counter_2ThugsD";
    AddStringAnimationTrigger(animName, 6, COMBAT_SOUND, R_CALF);
    AddStringAnimationTrigger(animName, 20, COMBAT_SOUND, L_FOOT);
    AddStringAnimationTrigger(animName, 26, COMBAT_SOUND, L_FOOT);
    AddAnimationTrigger(animName, 75, READY_TO_FIGHT);

    animName = preFix + "Double_Counter_2ThugsE";
    AddStringAnimationTrigger(animName, 23, COMBAT_SOUND, R_FOOT);
    AddAnimationTrigger(animName, 35, READY_TO_FIGHT);

    animName = preFix + "Double_Counter_2ThugsF";
    AddStringAnimationTrigger(animName, 8, COMBAT_SOUND, HEAD);
    AddStringAnimationTrigger(animName, 27, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 56, COMBAT_SOUND, L_FOOT);
    AddAnimationTrigger(animName, 90, READY_TO_FIGHT);

    animName = preFix + "Double_Counter_2ThugsG";
    AddStringAnimationTrigger(animName, 6, COMBAT_SOUND, L_FOOT);
    AddStringAnimationTrigger(animName, 16, COMBAT_SOUND, L_FOOT);
    AddStringAnimationTrigger(animName, 21, COMBAT_SOUND, L_CALF);
    AddAnimationTrigger(animName, 32, READY_TO_FIGHT);

    animName = preFix + "Double_Counter_2ThugsH";
    AddStringAnimationTrigger(animName, 9, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 28, COMBAT_SOUND, L_FOOT);
    AddAnimationTrigger(animName, 45, READY_TO_FIGHT);

    animName = preFix + "Double_Counter_3ThugsA";
    AddStringAnimationTrigger(animName, 8, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 14, COMBAT_SOUND, R_FOOT);
    AddStringAnimationTrigger(animName, 29, COMBAT_SOUND, L_FOOT);
    AddStringAnimationTrigger(animName, 34, COMBAT_SOUND, L_FOOT);
    AddAnimationTrigger(animName, 52, READY_TO_FIGHT);

    animName = preFix + "Double_Counter_3ThugsB";
    AddStringAnimationTrigger(animName, 10, COMBAT_SOUND, L_FOOT);
    AddStringAnimationTrigger(animName, 25, COMBAT_SOUND, R_FOOT);
    AddStringAnimationTrigger(animName, 38, COMBAT_SOUND, L_FOOT);
    AddAnimationTrigger(animName, 56, READY_TO_FIGHT);

    animName = preFix + "Double_Counter_3ThugsC";
    AddStringAnimationTrigger(animName, 15, COMBAT_SOUND, L_HAND);
    AddStringAnimationTrigger(animName, 35, COMBAT_SOUND, L_FOOT);
    AddStringAnimationTrigger(animName, 48, COMBAT_SOUND, L_FOOT);
    AddAnimationTrigger(animName, 66, READY_TO_FIGHT);
}




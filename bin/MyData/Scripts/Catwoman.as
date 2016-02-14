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

        forwardAttacks.Sort();
        leftAttacks.Sort();
        rightAttacks.Sort();
        backAttacks.Sort();

        float min_dist = 2.5f;
        for (uint i=0; i<forwardAttacks.length; ++i)
        {
            if (forwardAttacks[i].impactDist >= min_dist)
                break;
            forwadCloseNum++;
        }
        for (uint i=0; i<rightAttacks.length; ++i)
        {
            if (rightAttacks[i].impactDist >= min_dist)
                break;
            rightCloseNum++;
        }
        for (uint i=0; i<backAttacks.length; ++i)
        {
            if (backAttacks[i].impactDist >= min_dist)
                break;
            backCloseNum++;
        }
        for (uint i=0; i<leftAttacks.length; ++i)
        {
            if (leftAttacks[i].impactDist >= min_dist)
                break;
            leftCloseNum++;
        }

        // if (d_log)
        Dump();
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
        String preFix = "CW_TG_Counter/";
        gMotionMgr.AddCounterMotions(preFix);
        AddMultiCounterMotions(preFix, true);
    }
};

class CatwomanRedirectState : PlayerRedirectState
{
    CatwomanRedirectState(Character@ c)
    {
        super(c);
        SetMotion("CW_Combat/Redirect");
    }
};

class CatwomanHitState : PlayerHitState
{
    CatwomanHitState(Character@ c)
    {
        super(c);
        String hitPrefix = "CW_Hit_Reaction/";
        AddMotion(hitPrefix + "HitReaction_Face_Right");
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
        if (has_redirect)
            stateMachine.AddState(CatwomanRedirectState(this));
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
    Global_CreateMotion(preFix + "HitReaction_Face_Right");
    Global_CreateMotion(preFix + "Hit_Reaction_SideLeft");
    Global_CreateMotion(preFix + "Hit_Reaction_SideRight");
    Global_CreateMotion(preFix + "HitReaction_Back");

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
}



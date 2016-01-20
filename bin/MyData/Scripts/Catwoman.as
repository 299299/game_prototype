// ==============================================
//
//    Catwoman Class
//
// ==============================================

const String CATWOMAN_MOVEMENT_GROUP = "CW_Movement/";

// -- non cost
float CATWOMAN_TRANSITION_DIST = 0.0f;

class CatwomanStandState : PlayerStandState
{
    CatwomanStandState(Character@ c)
    {
        super(c);
        animations.Push(GetAnimationName(CATWOMAN_MOVEMENT_GROUP + "Stand_Idle"));
        animations.Push(GetAnimationName(CATWOMAN_MOVEMENT_GROUP + "Stand_Idle_01"));
        animations.Push(GetAnimationName(CATWOMAN_MOVEMENT_GROUP + "Stand_Idle_02"));
        flags = FLAGS_ATTACK;
    }
};

class CatwomanTurnState : PlayerTurnState
{
    CatwomanTurnState(Character@ c)
    {
        super(c);
        AddMotion(CATWOMAN_MOVEMENT_GROUP + "Turn_Right_90");
        AddMotion(CATWOMAN_MOVEMENT_GROUP + "Turn_Right_180");
        AddMotion(CATWOMAN_MOVEMENT_GROUP + "Turn_Left_90");
    }
};

class CatwomanMoveState : PlayerMoveState
{
    CatwomanMoveState(Character@ c)
    {
        super(c);
        SetMotion(CATWOMAN_MOVEMENT_GROUP + "Walk_Forward");
    }
};

class CatwomanEvadeState : PlayerEvadeState
{
    CatwomanEvadeState(Character@ c)
    {
        super(c);
        String prefix = "CW_Movement/";
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
        // FORWARD
        //========================================================================

        // forward weak
        AddAttackMotion(forwardAttacks, "Attack_Close_Weak_Forward", 11, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Close_Weak_Forward_01", 12, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Close_Weak_Forward_02", 12, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Close_Weak_Forward_03", 11, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Close_Weak_Forward_04", 16, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Close_Weak_Forward_05", 12, ATTACK_PUNCH, L_HAND);

        // forward close
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_02", 14, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_03", 11, ATTACK_KICK, L_FOOT);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_04", 19, ATTACK_KICK, R_FOOT);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_05", 24, ATTACK_PUNCH, L_ARM);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_06", 20, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_07", 15, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_08", 18, ATTACK_PUNCH, R_ARM);
        AddAttackMotion(forwardAttacks, "Attack_Close_Run_Forward", 12, ATTACK_PUNCH, R_HAND);

        // forward far
        AddAttackMotion(forwardAttacks, "Attack_Far_Forward", 25, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Far_Forward_01", 17, ATTACK_KICK, R_FOOT);
        AddAttackMotion(forwardAttacks, "Attack_Far_Forward_02", 21, ATTACK_KICK, L_FOOT);
        AddAttackMotion(forwardAttacks, "Attack_Far_Forward_03", 22, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Far_Forward_04", 22, ATTACK_KICK, R_FOOT);
        AddAttackMotion(forwardAttacks, "Attack_Run_Far_Forward", 18, ATTACK_KICK, R_FOOT);

        //========================================================================
        // RIGHT
        //========================================================================
        // right weak
        AddAttackMotion(rightAttacks, "Attack_Close_Weak_Right", 12, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(rightAttacks, "Attack_Close_Weak_Right_01", 10, ATTACK_PUNCH, R_ARM);
        AddAttackMotion(rightAttacks, "Attack_Close_Weak_Right_02", 15, ATTACK_PUNCH, R_HAND);

        // right close
        AddAttackMotion(rightAttacks, "Attack_Close_Right", 16, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_01", 18, ATTACK_PUNCH, R_ARM);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_03", 11, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_04", 19, ATTACK_KICK, R_FOOT);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_05", 15, ATTACK_KICK, L_CALF);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_06", 20, ATTACK_KICK, R_FOOT);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_07", 18, ATTACK_PUNCH, R_ARM);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_08", 18, ATTACK_KICK, L_FOOT);

        // right far
        AddAttackMotion(rightAttacks, "Attack_Far_Right", 25, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(rightAttacks, "Attack_Far_Right_01", 15, ATTACK_KICK, L_CALF);
        // AddAttackMotion(rightAttacks, "Attack_Far_Right_02", 21, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(rightAttacks, "Attack_Far_Right_03", 29, ATTACK_KICK, L_FOOT);
        AddAttackMotion(rightAttacks, "Attack_Far_Right_04", 22, ATTACK_KICK, R_FOOT);

        //========================================================================
        // BACK
        //========================================================================
        // back weak
        AddAttackMotion(backAttacks, "Attack_Close_Weak_Back", 12, ATTACK_PUNCH, L_ARM);
        AddAttackMotion(backAttacks, "Attack_Close_Weak_Back_01", 12, ATTACK_PUNCH, R_HAND);

        AddAttackMotion(backAttacks, "Attack_Close_Back", 11, ATTACK_PUNCH, L_ARM);
        AddAttackMotion(backAttacks, "Attack_Close_Back_01", 16, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(backAttacks, "Attack_Close_Back_02", 18, ATTACK_KICK, L_FOOT);
        AddAttackMotion(backAttacks, "Attack_Close_Back_03", 21, ATTACK_KICK, R_FOOT);
        AddAttackMotion(backAttacks, "Attack_Close_Back_04", 18, ATTACK_KICK, R_FOOT);
        AddAttackMotion(backAttacks, "Attack_Close_Back_05", 14, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(backAttacks, "Attack_Close_Back_06", 15, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(backAttacks, "Attack_Close_Back_07", 14, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(backAttacks, "Attack_Close_Back_08", 17, ATTACK_KICK, L_FOOT);

        // back far
        AddAttackMotion(backAttacks, "Attack_Far_Back", 14, ATTACK_KICK, L_FOOT);
        AddAttackMotion(backAttacks, "Attack_Far_Back_01", 15, ATTACK_KICK, L_FOOT);
        AddAttackMotion(backAttacks, "Attack_Far_Back_02", 22, ATTACK_PUNCH, R_ARM);
        //AddAttackMotion(backAttacks, "Attack_Far_Back_03", 22, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(backAttacks, "Attack_Far_Back_04", 36, ATTACK_KICK, R_FOOT);

        //========================================================================
        // LEFT
        //========================================================================
        // left weak
        AddAttackMotion(leftAttacks, "Attack_Close_Weak_Left", 13, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(leftAttacks, "Attack_Close_Weak_Left_01", 12, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(leftAttacks, "Attack_Close_Weak_Left_02", 13, ATTACK_PUNCH, L_HAND);

        // left close
        AddAttackMotion(leftAttacks, "Attack_Close_Left", 7, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_01", 18, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_02", 13, ATTACK_KICK, R_FOOT);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_03", 21, ATTACK_KICK, L_FOOT);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_04", 21, ATTACK_KICK, R_FOOT);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_05", 15, ATTACK_KICK, L_FOOT);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_06", 12, ATTACK_KICK, R_FOOT);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_07", 15, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_08", 20, ATTACK_KICK, L_FOOT);

        // left far
        AddAttackMotion(leftAttacks, "Attack_Far_Left", 19, ATTACK_KICK, L_FOOT);
        AddAttackMotion(leftAttacks, "Attack_Far_Left_01", 22, ATTACK_KICK, R_FOOT);
        AddAttackMotion(leftAttacks, "Attack_Far_Left_02", 22, ATTACK_PUNCH, R_ARM);
        AddAttackMotion(leftAttacks, "Attack_Far_Left_03", 21, ATTACK_KICK, L_FOOT);
        AddAttackMotion(leftAttacks, "Attack_Far_Left_04", 23, ATTACK_KICK, R_FOOT);

        forwardAttacks.Sort();
        leftAttacks.Sort();
        rightAttacks.Sort();
        backAttacks.Sort();

        float min_dist = 2.0f;
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
        {
            Print("\n forward attacks(closeNum=" + forwadCloseNum + "): \n");
            DumpAttacks(forwardAttacks);
            Print("\n right attacks(closeNum=" + rightCloseNum + "): \n");
            DumpAttacks(rightAttacks);
            Print("\n back attacks(closeNum=" + backCloseNum + "): \n");
            DumpAttacks(backAttacks);
            Print("\n left attacks(closeNum=" + leftCloseNum + "): \n");
            DumpAttacks(leftAttacks);
        }
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
        AddCounterMotions(preFix);
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
        String hitPrefix = "CW_Combat_HitReaction/";
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
        AddMotion(preFix + "Beatdown_Strike_End_01");
        AddMotion(preFix + "Beatdown_Strike_End_02");
        AddMotion(preFix + "Beatdown_Strike_End_03");
        AddMotion(preFix + "Beatdown_Strike_End_04");
    }
};

class CatwomanBeatDownHitState : PlayerBeatDownHitState
{
    CatwomanBeatDownHitState(Character@ c)
    {
        super(c);
        String preFix = "CW_Attack/";
        AddMotion(preFix + "Beatdown_Test_01");
        AddMotion(preFix + "Beatdown_Test_02");
        AddMotion(preFix + "Beatdown_Test_03");
        AddMotion(preFix + "Beatdown_Test_04");
        AddMotion(preFix + "Beatdown_Test_05");
        AddMotion(preFix + "Beatdown_Test_06");
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
        stateMachine.AddState(CatwomanAttackState(this));
        stateMachine.AddState(CatwomanCounterState(this));
        stateMachine.AddState(CatwomanEvadeState(this));
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
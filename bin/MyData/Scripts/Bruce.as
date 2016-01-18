// ==============================================
//
//    Bruce Class
//
// ==============================================

const String BRUCE_MOVEMENT_GROUP = "BM_Combat_Movement/"; //"BM_Combat_Movement/"

// -- non cost
float BRUCE_TRANSITION_DIST = 0.0f;

class BruceStandState : PlayerStandState
{
    BruceStandState(Character@ c)
    {
        super(c);
        animations.Push(GetAnimationName(BRUCE_MOVEMENT_GROUP + "Stand_Idle"));
        animations.Push(GetAnimationName(BRUCE_MOVEMENT_GROUP + "Stand_Idle_01"));
        animations.Push(GetAnimationName(BRUCE_MOVEMENT_GROUP + "Stand_Idle_02"));
        flags = FLAGS_ATTACK;
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

class BruceMoveState : PlayerMoveState
{
    BruceMoveState(Character@ c)
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
        String prefix = "BM_Movement/";
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
        attacks.Push(AttackMotion("BM_Attack/" + name, frame, type, bName));
    }
};


class BruceCounterState : PlayerCounterState
{
    BruceCounterState(Character@ c)
    {
        super(c);
        String preFix = "BM_TG_Counter/";
        AddCounterMotions(preFix);
        AddMultiCounterMotions(preFix, true);
    }
};

class BruceRedirectState : PlayerRedirectState
{
    BruceRedirectState(Character@ c)
    {
        super(c);
        SetMotion("BM_Combat/Redirect");
    }
};

class BruceHitState : PlayerHitState
{
    BruceHitState(Character@ c)
    {
        super(c);
        String hitPrefix = "BM_Combat_HitReaction/";
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
        if (has_redirect)
            stateMachine.AddState(BruceRedirectState(this));
        stateMachine.AddState(BruceDeadState(this));
        stateMachine.AddState(BruceBeatDownHitState(this));
        stateMachine.AddState(BruceBeatDownEndState(this));
        stateMachine.AddState(BruceTransitionState(this));
        stateMachine.AddState(AnimationTestState(this));
    }
};
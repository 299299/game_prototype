// ==============================================
//
//    Bruce Class
//
// ==============================================

class DeathStrokeStandState : PlayerStandState
{
    DeathStrokeStandState(Character@ c)
    {
        super(c);
        AddMotion(DK_MOVEMENT_GROUP + "Combat_Stand_Idle");
        AddMotion(DK_MOVEMENT_GROUP + "Stand_Idle_After_Combat");
    }
};

class DeathStrokeRunState : PlayerRunState
{
    DeathStrokeRunState(Character@ c)
    {
        super(c);
        SetMotion(DK_MOVEMENT_GROUP + "Run_Forward_Combat");
    }
};

class DeathStrokeTurnState : PlayerTurnState
{
    DeathStrokeTurnState(Character@ c)
    {
        super(c);
        String preFix = "DK_Movement/";
        AddMotion(preFix + "Turn_Right_90");
        AddMotion(preFix + "Turn_Right_180");
        AddMotion(preFix + "Turn_Left_90");
    }
};

class DeathStrokeStandToWalkState : PlayerStandToWalkState
{
    DeathStrokeStandToWalkState(Character@ c)
    {
        super(c);
        String preFix = "DK_Movement/";
        AddMotion(preFix + "Turn_Right_90");
        AddMotion(preFix + "Turn_Right_180");
        AddMotion(preFix + "Turn_Left_90");
    }
};

class DeathStrokeStandToRunState : PlayerStandToRunState
{
    DeathStrokeStandToRunState(Character@ c)
    {
        super(c);
        AddMotion(DK_MOVEMENT_GROUP + "Stand_To_Run_Right_180");
    }
};

class DeathStrokeWalkState : PlayerWalkState
{
    DeathStrokeWalkState(Character@ c)
    {
        super(c);
        SetMotion(DK_MOVEMENT_GROUP + "Walk_Forward_Combat");
    }
};

class DeathStrokeAttackState : PlayerAttackState
{
    DeathStrokeAttackState(Character@ c)
    {
        super(c);
        PostInit();
    }
};

class DeathStrokeCounterState : PlayerCounterState
{
    DeathStrokeCounterState(Character@ c)
    {
        super(c);
    }
};

class DeathStrokeHitState : PlayerHitState
{
    DeathStrokeHitState(Character@ c)
    {
        super(c);
        String hitPrefix = "BM_HitReaction/";
        AddMotion(hitPrefix + "HitReaction_Face_Right");
        AddMotion(hitPrefix + "Hit_Reaction_SideLeft");
        AddMotion(hitPrefix + "HitReaction_Back");
        AddMotion(hitPrefix + "Hit_Reaction_SideRight");
    }
};

class DeathStrokeDeadState : PlayerDeadState
{
    DeathStrokeDeadState(Character@ c)
    {
        super(c);
        String prefix = "BM_Death_Primers/";
        AddMotion(prefix + "Death_Front");
        AddMotion(prefix + "Death_Side_Left");
        AddMotion(prefix + "Death_Back");
        AddMotion(prefix + "Death_Side_Right");
    }
};

class DeathStrokeTransitionState : PlayerTransitionState
{
    DeathStrokeTransitionState(Character@ c)
    {
        super(c);
        SetMotion("BM_Combat/Into_Takedown");
        LogPrint("Bruce-Transition Dist=" + motion.endDistance);
    }
};

class DeathStroke : Player
{
    DeathStroke()
    {
        super();
    }

    void AddStates()
    {
        stateMachine.AddState(DeathStrokeStandState(this));
        stateMachine.AddState(DeathStrokeRunState(this));
        stateMachine.AddState(AnimationTestState(this));

        stateMachine.AddState(DeathStrokeAttackState(this));
        stateMachine.AddState(DeathStrokeCounterState(this));
        stateMachine.AddState(DeathStrokeHitState(this));
        stateMachine.AddState(DeathStrokeDeadState(this));
        stateMachine.AddState(DeathStrokeTransitionState(this));

        stateMachine.AddState(DeathStrokeWalkState(this));
        stateMachine.AddState(DeathStrokeTurnState(this));
        stateMachine.AddState(DeathStrokeStandToWalkState(this));
        stateMachine.AddState(DeathStrokeStandToRunState(this));
    }
};

void CreateDeathStrokeMotions()
{
    AssignMotionRig("Models/dk.mdl");

    String preFix = DK_MOVEMENT_GROUP;
    Global_AddAnimation(preFix + "Combat_Stand_Idle");
    Global_AddAnimation(preFix + "Stand_Idle_After_Combat");
    Global_CreateMotion(preFix + "Run_Forward_Combat", kMotion_Z, kMotion_Z, -1, true);
    // Global_CreateMotion(preFix + "Run_Right_Passing_To_Run_Right_180", kMotion_Turn, kMotion_ZR, 28);

    int locomotionFlags = kMotion_XZR;
    preFix = "DK_Movement/";
    Global_CreateMotion(preFix + "Turn_Right_90", locomotionFlags, kMotion_R, 16);
    Global_CreateMotion(preFix + "Turn_Right_180", locomotionFlags, kMotion_R, 25);
    Global_CreateMotion(preFix + "Turn_Left_90", locomotionFlags, kMotion_R, 14);
    Global_CreateMotion(DK_MOVEMENT_GROUP + "Walk_Forward_Combat", kMotion_Z, kMotion_Z, -1, true);

    preFix = DK_MOVEMENT_GROUP;
    Global_CreateMotion(preFix + "Stand_To_Walk_Right_90", locomotionFlags, kMotion_ZR, 21);
    Global_CreateMotion(preFix + "Stand_To_Walk_Right_180", locomotionFlags, kMotion_ZR, 25);
    Global_CreateMotion(preFix + "Stand_To_Run_Right_90", locomotionFlags, kMotion_ZR, 18);
    Global_CreateMotion(preFix + "Stand_To_Run_Right_180", locomotionFlags, kMotion_ZR, 25);

    CreateBruceCombatMotions();
}

void CreateDeathStrokeCombatMotions()
{
    BM_Game_MotionManager@ mgr = cast<BM_Game_MotionManager>(gMotionMgr);

    String preFix = "BM_HitReaction/";
    Global_CreateMotion(preFix + "HitReaction_Back"); // back attacked
    Global_CreateMotion(preFix + "HitReaction_Face_Right"); // front punched
    Global_CreateMotion(preFix + "Hit_Reaction_SideLeft"); // left attacked
    Global_CreateMotion(preFix + "Hit_Reaction_SideRight"); // right attacked


    preFix = "BM_Death_Primers/";
    Global_CreateMotion(preFix + "Death_Front");
    Global_CreateMotion(preFix + "Death_Back");
    Global_CreateMotion(preFix + "Death_Side_Left");
    Global_CreateMotion(preFix + "Death_Side_Right");
}

void AddDeathStrokeCombatAnimationTriggers()
{
}

void AddDeathStrokeAnimationTriggers()
{

    AddDeathStrokeCombatAnimationTriggers();
}


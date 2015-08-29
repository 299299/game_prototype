#include "Scripts/Test/Character.as"

class PlayerStandState : CharacterState
{
    Array<String>           animations;

    PlayerStandState(Node@ n, Character@ c)
    {
        super(n, c);
        name = "StandState";
        animations.Push("Animation/Stand_Idle.ani");
        animations.Push("Animation/Stand_Idle_01.ani");
        animations.Push("Animation/Stand_Idle_02.ani");
    }

    void Enter(State@ lastState)
    {
        AnimationController@ ctrl = characterNode.GetComponent("AnimationController");
        if (ctrl !is null)
            ctrl.PlayExclusive(animations[RandomInt(animations.length)], 0, true, 0.1);
    }

    void Update(float dt)
    {
        if (!gInput.inLeftStickInDeadZone() && gInput.isLeftStickStationary())
            ownner.stateMachine.ChangeState("StandToMoveState");
    }
};

class PlayerStandToMoveState : CharacterState
{
    Motion@ motion;

    PlayerStandToMoveState(Node@ n, Character@ c)
    {
        super(n, c);
        name = "StandToMoveState";
        @motion = Motion("Animation/Stand_To_Walk_Left_90.ani", -90, 26, false, true);
    }

    void Update(float dt)
    {
        if (motion.Move(dt, node))
            ownner.stateMachine.ChangeState("StandState");
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        motion.DebugDraw(debug, characterNode);
    }
};

class PlayerMoveState : CharacterState
{
    Motion@ motion;

    PlayerMoveState(Node@ n, Character@ c)
    {
        super(n, c);
        name = "MoveState";
    }

    void Update(float dt)
    {

    }
};

class Player : Character
{
    void Start()
    {
        stateMachine.AddState(PlayerStandState(node, this));
        stateMachine.AddState(PlayerStandToMoveState(node, this));
        stateMachine.AddState(PlayerMoveState(node, this));
        stateMachine.ChangeState("StandState");
    }

    void Update(float dt)
    {

    }
};